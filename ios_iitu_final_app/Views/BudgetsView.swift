import SwiftUI

struct BudgetsView: View {
    @EnvironmentObject var coreDataService: CoreDataService
    @StateObject private var viewModel: BudgetViewModel
    @State private var showAddBudget = false

    init() {
        _viewModel = StateObject(wrappedValue: BudgetViewModel(coreDataService: CoreDataService.shared))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.budgets.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.pie")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)

                        Text("Нет бюджетов")
                            .font(.headline)

                        Text("Создайте бюджет, чтобы контролировать расходы")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Button(action: { showAddBudget = true }) {
                            Text("Создать бюджет")
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
                        // Warning budgets
                        if !viewModel.warningBudgets.isEmpty {
                            Section(header: Text("⚠️ Предупреждение")) {
                                ForEach(viewModel.warningBudgets) { budget in
                                    BudgetRowView(budget: budget, viewModel: viewModel)
                                }
                            }
                        }

                        // Normal budgets
                        if !viewModel.normalBudgets.isEmpty {
                            Section(header: Text("✅ В норме")) {
                                ForEach(viewModel.normalBudgets) { budget in
                                    BudgetRowView(budget: budget, viewModel: viewModel)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Бюджеты")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddBudget = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddBudget) {
                AddBudgetView(isPresented: $showAddBudget, viewModel: viewModel)
            }
        }
    }
}

struct BudgetRowView: View {
    @EnvironmentObject var coreDataService: CoreDataService
    let budget: Budget
    let viewModel: BudgetViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.getCategoryName(budget.categoryId))
                        .font(.callout)
                        .fontWeight(.semibold)

                    Text("\(budget.spent.formatted()) / \(budget.limit.formatted()) \(budget.currency)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(budget.percentage))%")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(budget.isExceeded ? .red : (budget.isWarning ? .orange : .green))

                    Text(budget.period.displayName)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(budget.isExceeded ? Color.red : (budget.isWarning ? Color.orange : Color.green))
                        .frame(width: geo.size.width * (budget.percentage / 100))
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, 8)
    }
}

struct AddBudgetView: View {
    @EnvironmentObject var coreDataService: CoreDataService
    @Binding var isPresented: Bool
    let viewModel: BudgetViewModel

    @State private var selectedCategory: Category?
    @State private var limitAmount: String = ""
    @State private var selectedPeriod: BudgetPeriod = .month

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Категория")) {
                    Picker("Категория", selection: $selectedCategory) {
                        Text("Выбрать").tag(Optional<Category>(nil))

                        ForEach(coreDataService.categories.filter { $0.type == .expense }) { category in
                            HStack {
                                Text(category.icon)
                                Text(category.name)
                            }
                            .tag(Optional(category))
                        }
                    }
                }

                Section(header: Text("Лимит")) {
                    HStack {
                        TextField("Сумма", text: $limitAmount)
                            .keyboardType(.decimalPad)

                        Text("KZT")
                            .foregroundColor(.gray)
                    }
                }

                Section(header: Text("Период")) {
                    Picker("Период", selection: $selectedPeriod) {
                        ForEach(BudgetPeriod.allCases, id: \.self) { period in
                            Text(period.displayName).tag(period)
                        }
                    }
                }

                Section {
                    Button(action: saveBudget) {
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
            .navigationTitle("Новый бюджет")
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

    private func saveBudget() {
        guard let category = selectedCategory,
              let limit = Double(limitAmount), limit > 0 else {
            return
        }

        let budget = Budget(
            categoryId: category.id,
            limit: limit,
            period: selectedPeriod,
            startDate: Date(),
            currency: "KZT"
        )

        viewModel.addBudget(budget)
        isPresented = false
    }
}

#Preview {
    BudgetsView()
        .environmentObject(CoreDataService.shared)
}
