import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var coreDataService: CoreDataService
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showAccounts = false
    @State private var showAddAccount = false

    var body: some View {
        NavigationStack {
            Form {
                // Accounts Section
                Section(header: Text("Счета")) {
                    NavigationLink(destination: AccountsManagementView(showAddAccount: $showAddAccount)) {
                        HStack {
                            Image(systemName: "creditcard")
                            Text("Управлять счетами")
                            Spacer()
                            Text("\(coreDataService.accounts.count)")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                }

                // Categories Section
                Section(header: Text("Категории")) {
                    NavigationLink(destination: CategoriesManagementView()) {
                        HStack {
                            Image(systemName: "tag")
                            Text("Управлять категориями")
                            Spacer()
                            Text("\(coreDataService.categories.count)")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                }

                // Goals Section
                Section(header: Text("Цели")) {
                    NavigationLink(destination: GoalsView()) {
                        HStack {
                            Image(systemName: "target")
                            Text("Финансовые цели")
                            Spacer()
                            Text("\(coreDataService.goals.count)")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                }

                // Analytics Section
                Section(header: Text("Аналитика")) {
                    NavigationLink(destination: AnalyticsView()) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                            Text("Статистика")
                        }
                    }
                }

                // Security Section
                Section(header: Text("Безопасность")) {
                    Button(action: {
                        authManager.authenticate()
                    }) {
                        HStack {
                            Image(systemName: "lock")
                            Text("Разблокировать по биометрии")
                        }
                    }
                }

                // App Info Section
                Section(header: Text("О приложении")) {
                    HStack {
                        Text("Версия")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }

                    HStack {
                        Text("Разработчик")
                        Spacer()
                        Text("FinanceFlow")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AccountsManagementView: View {
    @EnvironmentObject var coreDataService: CoreDataService
    @Binding var showAddAccount: Bool

    var body: some View {
        VStack(spacing: 0) {
            List {
                if coreDataService.accounts.isEmpty {
                    VStack(alignment: .center, spacing: 12) {
                        Image(systemName: "creditcard")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)

                        Text("Нет счетов")
                            .font(.headline)

                        Text("Добавьте счет для начала")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(coreDataService.accounts) { account in
                        HStack {
                            Image(systemName: account.type.icon)
                                .font(.title3)
                                .foregroundColor(.blue)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(account.name)
                                    .fontWeight(.semibold)

                                Text(account.type.displayName)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(String(format: "%.2f", account.balance))")
                                    .fontWeight(.semibold)

                                Text(account.currency)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Счета")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddAccount = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddAccount) {
            AddAccountView(isPresented: $showAddAccount)
        }
    }
}

struct AddAccountView: View {
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

struct CategoriesManagementView: View {
    @EnvironmentObject var coreDataService: CoreDataService

    var body: some View {
        List {
            ForEach([OperationType.expense, OperationType.income], id: \.self) { type in
                Section(header: Text(type.displayName)) {
                    ForEach(coreDataService.categories.filter { $0.type == type }) { category in
                        HStack {
                            Text(category.icon)
                                .font(.title3)

                            Text(category.name)
                                .fontWeight(category.isCustom ? .semibold : .regular)

                            if category.isCustom {
                                Spacer()
                                Text("Custom")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Категории")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GoalsView: View {
    @EnvironmentObject var coreDataService: CoreDataService
    @State private var showAddGoal = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if coreDataService.goals.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "target")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)

                        Text("Нет целей")
                            .font(.headline)

                        Text("Создайте финансовую цель")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Button(action: { showAddGoal = true }) {
                            Text("Создать цель")
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(coreDataService.goals) { goal in
                            VStack(spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(goal.name)
                                            .font(.callout)
                                            .fontWeight(.semibold)

                                        Text("Осталось: \(goal.daysRemaining) дн.")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("\(Int(goal.percentage))%")
                                            .font(.callout)
                                            .fontWeight(.semibold)

                                        Text("\(String(format: "%.2f", goal.currentAmount)) / \(String(format: "%.2f", goal.targetAmount))")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                }

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color(.systemGray6))

                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.blue)
                                            .frame(width: geo.size.width * (goal.percentage / 100))
                                    }
                                }
                                .frame(height: 8)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Цели")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddGoal = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddGoal) {
                AddGoalView(isPresented: $showAddGoal)
            }
        }
    }
}

struct AddGoalView: View {
    @EnvironmentObject var coreDataService: CoreDataService
    @Binding var isPresented: Bool

    @State private var goalName: String = ""
    @State private var targetAmount: String = ""
    @State private var selectedAccount: Account?
    @State private var deadline: Date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Название цели")) {
                    TextField("Название", text: $goalName)
                }

                Section(header: Text("Целевая сумма")) {
                    HStack {
                        TextField("0.00", text: $targetAmount)
                            .keyboardType(.decimalPad)

                        Text("KZT")
                            .foregroundColor(.gray)
                    }
                }

                Section(header: Text("Дедлайн")) {
                    DatePicker("Дата", selection: $deadline, displayedComponents: .date)
                }

                Section(header: Text("Счет")) {
                    Picker("Счет", selection: $selectedAccount) {
                        Text("Выбрать").tag(Optional<Account>(nil))

                        ForEach(coreDataService.accounts) { account in
                            HStack {
                                Image(systemName: account.type.icon)
                                Text(account.name)
                            }
                            .tag(Optional(account))
                        }
                    }
                }

                Section {
                    Button(action: saveGoal) {
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
            .navigationTitle("Новая цель")
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

    private func saveGoal() {
        guard !goalName.isEmpty, let targetValue = Double(targetAmount), targetValue > 0,
              let account = selectedAccount else {
            return
        }

        let goal = Goal(
            name: goalName,
            targetAmount: targetValue,
            deadline: deadline,
            currency: "KZT",
            accountId: account.id
        )

        coreDataService.addGoal(goal)
        isPresented = false
    }
}

struct AnalyticsView: View {
    @EnvironmentObject var coreDataService: CoreDataService
    @StateObject private var viewModel: AnalyticsViewModel

    init() {
        _viewModel = StateObject(wrappedValue: AnalyticsViewModel(coreDataService: CoreDataService.shared))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Monthly Summary
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Доход")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text("+\(String(format: "%.2f", viewModel.monthlyIncome))")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Расход")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text("-\(String(format: "%.2f", viewModel.monthlyExpenses))")
                            .font(.headline)
                            .foregroundColor(.red)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .padding()

                // Top Categories
                VStack(alignment: .leading, spacing: 12) {
                    Text("Топ категории")
                        .font(.headline)

                    ForEach(viewModel.topCategories, id: \.0) { category, amount in
                        HStack {
                            Text(category)
                                .font(.callout)

                            Spacer()

                            Text("\(String(format: "%.2f", amount))")
                                .fontWeight(.semibold)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding()

                Spacer()
            }
        }
        .navigationTitle("Статистика")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AuthenticationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var pin: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)

            Text("FinanceFlow")
                .font(.title)
                .fontWeight(.bold)

            Text("Защита данных")
                .foregroundColor(.gray)

            Button(action: {
                authManager.authenticate()
            }) {
                HStack {
                    Image(systemName: "faceid")
                    Text("Разблокировать по FaceID")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(8)
            }

            Spacer()
        }
        .padding()
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    SettingsView()
        .environmentObject(CoreDataService.shared)
        .environmentObject(AuthenticationManager.shared)
}
