import SwiftUI

struct AddOperationView: View {
    @EnvironmentObject var coreDataService: CoreDataService
    @Environment(\.dismiss) var dismiss

    @State private var operationType: OperationType = .expense
    @State private var amount: String = ""
    @State private var selectedCategory: Category?
    @State private var selectedAccount: Account?
    @State private var description: String = ""
    @State private var selectedDate: Date = Date()
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showNoAccountsAlert = false
    @State private var showCreateAccount = false
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                // Operation Type
                Section(header: Text("Тип операции")) {
                    Picker("Тип", selection: $operationType) {
                        ForEach(OperationType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: operationType) { newType in
                        // Очистить категорию если она не подходит для нового типа
                        if let category = selectedCategory, category.type != newType {
                            selectedCategory = nil
                        }
                    }
                }

                // Amount
                Section(header: Text("Сумма")) {
                    HStack {
                        TextField("Сумма", text: $amount)
                            .keyboardType(.decimalPad)

                        Text("KZT")
                            .foregroundColor(.gray)
                    }
                }

                // Category
                Section(header: Text("Категория")) {
                    if let selected = selectedCategory {
                        HStack {
                            Text(selected.icon)
                            Text(selected.name)
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }

                    NavigationLink(destination: CategoryPickerView(selectedCategory: $selectedCategory, operationType: operationType)) {
                        Text("Выбрать категорию")
                    }
                }

                // Account
                Section(header: Text("Счёт")) {
                    if let selected = selectedAccount {
                        HStack {
                            Image(systemName: selected.type.icon)
                            Text(selected.name)
                            Spacer()
                            Text("\(String(format: "%.2f", selected.balance)) \(selected.currency)")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }

                    NavigationLink(destination: AccountPickerView(selectedAccount: $selectedAccount)) {
                        Text("Выбрать счёт")
                    }
                }

                // Description
                Section(header: Text("Описание")) {
                    TextEditor(text: $description)
                        .frame(minHeight: 80)
                }

                // Date
                Section(header: Text("Дата")) {
                    DatePicker("Дата", selection: $selectedDate, displayedComponents: .date)
                }

                // Save Button
                Section {
                    Button(action: saveOperation) {
                        if isSaving {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .tint(.white)
                                Spacer()
                            }
                        } else {
                            HStack {
                                Spacer()
                                Text("Сохранить")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(8)
                    .disabled(isSaving)
                }
            }
            .navigationTitle("Добавить операцию")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Ошибка", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .alert("Нет счетов", isPresented: $showNoAccountsAlert) {
                Button("Создать счет") {
                    showCreateAccount = true
                }
                Button("Отмена", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Необходимо создать хотя бы один счет для добавления операции")
            }
            .sheet(isPresented: $showCreateAccount) {
                AddAccountViewForAddOperation(isPresented: $showCreateAccount)
                    .environmentObject(coreDataService)
            }
            .onAppear {
                if coreDataService.accounts.isEmpty {
                    showNoAccountsAlert = true
                }
            }
        }
    }

    private func saveOperation() {
        guard !amount.isEmpty, let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "Введите корректную сумму"
            showError = true
            return
        }

        guard let account = selectedAccount else {
            errorMessage = "Выберите счёт"
            showError = true
            return
        }

        guard let category = selectedCategory else {
            errorMessage = "Выберите категорию"
            showError = true
            return
        }

        isSaving = true

        let operation = Operation(
            type: operationType,
            amount: amountValue,
            currency: "KZT",
            categoryId: category.id,
            date: selectedDate,
            accountId: account.id,
            description: description
        )

        coreDataService.addOperation(operation, toAccount: account.id)

        // Small delay for visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isSaving = false
            dismiss()
        }
    }
}

struct AddAccountViewForAddOperation: View {
    @EnvironmentObject var coreDataService: CoreDataService
    @Binding var isPresented: Bool

    @State private var accountName: String = ""
    @State private var accountType: AccountType = .card
    @State private var balance: String = "0"
    @State private var currency: String = "KZT"

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Название")) {
                    TextField("Название счета", text: $accountName)
                }

                Section(header: Text("Тип")) {
                    Picker("Тип", selection: $accountType) {
                        ForEach(AccountType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                Section(header: Text("Баланс")) {
                    HStack {
                        TextField("0.00", text: $balance)
                            .keyboardType(.decimalPad)

                        TextField("Валюта", text: $currency)
                            .frame(width: 60)
                    }
                }

                Section {
                    Button(action: saveAccount) {
                        HStack {
                            Spacer()
                            Text("Создать")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                }
            }
            .navigationTitle("Новый счет")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        isPresented = false
                    }
                }
            }
        }
    }

    private func saveAccount() {
        let balanceValue = Double(balance) ?? 0

        let account = Account(
            name: accountName.isEmpty ? accountType.displayName : accountName,
            balance: balanceValue,
            currency: currency,
            type: accountType
        )

        coreDataService.addAccount(account)
        isPresented = false
    }
}

struct CategoryPickerView: View {
    @EnvironmentObject var coreDataService: CoreDataService
    @Binding var selectedCategory: Category?
    let operationType: OperationType

    var body: some View {
        List {
            ForEach(coreDataService.categories.filter { $0.type == operationType }) { category in
                Button(action: {
                    selectedCategory = category
                }) {
                    HStack {
                        Text(category.icon)
                            .font(.title2)

                        Text(category.name)

                        Spacer()

                        if selectedCategory?.id == category.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.black)
            }
        }
        .navigationTitle("Выберите категорию")
    }
}

struct AccountPickerView: View {
    @EnvironmentObject var coreDataService: CoreDataService
    @Binding var selectedAccount: Account?

    var body: some View {
        List {
            ForEach(coreDataService.accounts) { account in
                Button(action: {
                    selectedAccount = account
                }) {
                    HStack {
                        Image(systemName: account.type.icon)
                        Text(account.name)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(String(format: "%.2f", account.balance))")
                                .fontWeight(.semibold)

                            Text(account.currency)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        if selectedAccount?.id == account.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.black)
            }
        }
        .navigationTitle("Выберите счёт")
    }
}

#Preview {
    AddOperationView()
        .environmentObject(CoreDataService.shared)
}
