import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var coreDataService: CoreDataService
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showAccounts = false
    @State private var showAddAccount = false
    @State private var showResetConfirmation = false

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
                    if authManager.isBiometricAvailable {
                        HStack {
                            Image(systemName: authManager.biometricType == .faceID ? "faceid" : "touchid")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(authManager.biometricType == .faceID ? "Face ID" : "Touch ID")
                                    .fontWeight(.semibold)
                                Text("Включено")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { authManager.keychain.isBiometricEnabled() },
                                set: { newValue in
                                    if newValue {
                                        authManager.setupBiometric()
                                    } else {
                                        authManager.disableBiometric()
                                    }
                                }
                            ))
                        }

                        if let error = authManager.authError {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .padding(.vertical, 4)
                        }
                    } else {
                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(.gray)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Биометрия")
                                    .fontWeight(.semibold)
                                Text("Недоступна на этом устройстве")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
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

                // Danger Zone Section
                Section(header: Text("Опасные действия")) {
                    Button(action: { showResetConfirmation = true }) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("Сбросить все данные")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Сбросить все данные?", isPresented: $showResetConfirmation) {
                Button("Сбросить", role: .destructive) {
                    resetAllData()
                }
                Button("Отмена", role: .cancel) { }
            } message: {
                Text("Все ваши данные (счета, транзакции, категории, цели) будут удалены. Это действие невозможно отменить!")
            }
        }
    }

    private func resetAllData() {
        coreDataService.resetAllData()
    }
}

struct AccountsManagementView: View {
    @EnvironmentObject var coreDataService: CoreDataService
    @Binding var showAddAccount: Bool
    @State private var defaultAccountId: UUID? = UserDefaults.standard.defaultAccountId

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
                        Button(action: {
                            defaultAccountId = account.id
                            UserDefaults.standard.setDefaultAccountId(account.id)
                        }) {
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

                                HStack(spacing: 12) {
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("\(String(format: "%.2f", account.balance))")
                                            .fontWeight(.semibold)

                                        Text(account.currency)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }

                                    if defaultAccountId == account.id {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .foregroundColor(.black)
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
    @State private var showAddCategory = false
    @State private var categoryToDelete: Category?
    @State private var showDeleteConfirmation = false

    var body: some View {
        List {
            ForEach([OperationType.expense, OperationType.income], id: \.self) { type in
                Section(header: Text(type.displayName)) {
                    ForEach(coreDataService.categories.filter { $0.type == type }) { category in
                        HStack {
                            Text(category.icon)
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(category.name)
                                    .fontWeight(category.isCustom ? .semibold : .regular)

                                if category.isCustom {
                                    Text("Custom")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }

                            Spacer()

                            if category.isCustom {
                                Button(action: {
                                    categoryToDelete = category
                                    showDeleteConfirmation = true
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Категории")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddCategory = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddCategory) {
            AddCategoryView(isPresented: $showAddCategory)
                .environmentObject(coreDataService)
        }
        .alert("Удалить категорию", isPresented: $showDeleteConfirmation) {
            Button("Удалить", role: .destructive) {
                if let category = categoryToDelete {
                    coreDataService.deleteCategory(category.id)
                    categoryToDelete = nil
                }
            }
            Button("Отмена", role: .cancel) {
                categoryToDelete = nil
            }
        } message: {
            Text("Это удалит категорию и все связанные транзакции. Это действие невозможно отменить.")
        }
    }
}

struct AddCategoryView: View {
    @EnvironmentObject var coreDataService: CoreDataService
    @Binding var isPresented: Bool

    @State private var categoryName: String = ""
    @State private var categoryIcon: String = "📌"
    @State private var categoryType: OperationType = .expense
    @State private var selectedColor: String = "FF6B6B"
    @State private var showError = false
    @State private var errorMessage = ""

    let colors = [
        ("FF6B6B", "Красный"),
        ("4ECDC4", "Бирюзовый"),
        ("95E1D3", "Мятный"),
        ("FFB6B9", "Розовый"),
        ("C7CEEA", "Сиреневый"),
        ("B5EAD7", "Светло-зелёный"),
        ("FFDAC1", "Персиковый"),
        ("E0BBE4", "Лаванда"),
        ("D4F1F4", "Голубой"),
        ("CCCCCC", "Серый"),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Название")) {
                    TextField("Название категории", text: $categoryName)
                }

                Section(header: Text("Тип")) {
                    Picker("Тип", selection: $categoryType) {
                        ForEach([OperationType.expense, OperationType.income], id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                Section(header: Text("Иконка")) {
                    TextField("Выберите иконку (emoji)", text: $categoryIcon)
                        .font(.title2)
                }

                Section(header: Text("Цвет")) {
                    Picker("Цвет", selection: $selectedColor) {
                        ForEach(colors, id: \.0) { color, label in
                            HStack {
                                Circle()
                                    .fill(Color(hex: color) ?? .blue)
                                    .frame(width: 20, height: 20)
                                Text(label)
                            }
                            .tag(color)
                        }
                    }
                }

                Section {
                    Button(action: saveCategory) {
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
            .navigationTitle("Новая категория")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        isPresented = false
                    }
                }
            }
            .alert("Ошибка", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func saveCategory() {
        guard !categoryName.isEmpty else {
            errorMessage = "Введите название категории"
            showError = true
            return
        }

        guard !categoryIcon.isEmpty else {
            errorMessage = "Выберите иконку"
            showError = true
            return
        }

        let category = Category(
            name: categoryName,
            icon: categoryIcon,
            color: selectedColor,
            type: categoryType,
            isCustom: true
        )

        coreDataService.addCategory(category)
        isPresented = false
    }
}

struct GoalsView: View {
    @EnvironmentObject var coreDataService: CoreDataService
    @State private var showAddGoal = false
    @State private var selectedGoal: Goal?
    @State private var showGoalDetail = false

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
                            Button(action: {
                                selectedGoal = goal
                                showGoalDetail = true
                            }) {
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
                                                .foregroundColor(goal.percentage >= 100 ? .green : (goal.percentage >= 80 ? .orange : .blue))

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
                                                .fill(goal.percentage >= 100 ? Color.green : (goal.percentage >= 80 ? Color.orange : Color.blue))
                                                .frame(width: geo.size.width * (goal.percentage / 100))
                                        }
                                    }
                                    .frame(height: 8)
                                }
                                .padding(.vertical, 8)
                            }
                            .foregroundColor(.black)
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
            .sheet(isPresented: $showGoalDetail) {
                if let goal = selectedGoal {
                    GoalDetailView(isPresented: $showGoalDetail, goal: goal)
                        .environmentObject(coreDataService)
                }
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

struct GoalDetailView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var coreDataService: CoreDataService

    let goal: Goal
    @State private var currentAmount: String = ""
    @State private var showAddFunds = false
    @State private var addAmount: String = ""
    @State private var showDeleteConfirmation = false

    var progressColor: Color {
        if goal.percentage >= 100 {
            return .green
        } else if goal.percentage >= 80 {
            return .orange
        } else {
            return .blue
        }
    }

    var remainingAmount: Double {
        max(goal.targetAmount - goal.currentAmount, 0)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Goal Header
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(goal.name)
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("Осталось: \(goal.daysRemaining) дней")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(Int(goal.percentage))%")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(progressColor)

                            if goal.percentage >= 100 {
                                Text("Завершено!")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else {
                                Text("Осталось: \(String(format: "%.2f", remainingAmount))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))

                            RoundedRectangle(cornerRadius: 8)
                                .fill(progressColor)
                                .frame(width: geo.size.width * (goal.percentage / 100))
                        }
                    }
                    .frame(height: 12)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Stats
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Текущая сумма")
                                .font(.caption)
                                .foregroundColor(.gray)

                            Text("\(String(format: "%.2f", goal.currentAmount)) \(goal.currency)")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Целевая сумма")
                                .font(.caption)
                                .foregroundColor(.gray)

                            Text("\(String(format: "%.2f", goal.targetAmount)) \(goal.currency)")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Дедлайн")
                                .font(.caption)
                                .foregroundColor(.gray)

                            Text(goal.deadline.formatted(date: .abbreviated, time: .omitted))
                                .font(.headline)
                                .fontWeight(.semibold)
                        }

                        Spacer()

                        if let account = coreDataService.accounts.first(where: { $0.id == goal.accountId }) {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Счет")
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                HStack(spacing: 4) {
                                    Image(systemName: account.type.icon)
                                    Text(account.name)
                                }
                                .font(.headline)
                                .fontWeight(.semibold)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                Spacer()

                // Action Buttons
                VStack(spacing: 12) {
                    if goal.percentage < 100 {
                        Button(action: { showAddFunds = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Пополнить цель")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundColor(.white)
                            .background(Color.green)
                            .cornerRadius(8)
                        }
                    }

                    Button(action: { showDeleteConfirmation = true }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Удалить цель")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundColor(.white)
                        .background(Color.red)
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Детали цели")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Закрыть") {
                        isPresented = false
                    }
                }
            }
            .sheet(isPresented: $showAddFunds) {
                AddFundsToGoalView(isPresented: $showAddFunds, goal: goal)
                    .environmentObject(coreDataService)
            }
            .alert("Удалить цель", isPresented: $showDeleteConfirmation) {
                Button("Удалить", role: .destructive) {
                    coreDataService.deleteGoal(goal.id)
                    isPresented = false
                }
                Button("Отмена", role: .cancel) { }
            } message: {
                Text("Эта цель будет удалена. Это действие невозможно отменить.")
            }
        }
    }
}

struct AddFundsToGoalView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var coreDataService: CoreDataService

    let goal: Goal
    @State private var addAmount: String = ""
    @State private var showError = false
    @State private var errorMessage = ""

    var remainingToGoal: Double {
        max(goal.targetAmount - goal.currentAmount, 0)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Информация о цели")) {
                    HStack {
                        Text("Текущая сумма")
                        Spacer()
                        Text("\(String(format: "%.2f", goal.currentAmount)) \(goal.currency)")
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Text("Требуется еще")
                        Spacer()
                        Text("\(String(format: "%.2f", remainingToGoal)) \(goal.currency)")
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }

                Section(header: Text("Добавить средства")) {
                    HStack {
                        TextField("Сумма", text: $addAmount)
                            .keyboardType(.decimalPad)

                        Text(goal.currency)
                            .foregroundColor(.gray)
                    }
                }

                Section {
                    HStack {
                        ForEach([Double(100), Double(500), Double(1000), Double(5000)], id: \.self) { amount in
                            if amount <= remainingToGoal {
                                Button(action: { addAmount = String(Int(amount)) }) {
                                    Text("+\(Int(amount))")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(6)
                                }
                            }
                        }
                        Spacer()
                    }
                }

                Section {
                    Button(action: addFunds) {
                        HStack {
                            Spacer()
                            Text("Добавить")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .cornerRadius(8)
                    }
                }
            }
            .navigationTitle("Пополнить цель")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        isPresented = false
                    }
                }
            }
            .alert("Ошибка", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func addFunds() {
        guard let amount = Double(addAmount), amount > 0 else {
            errorMessage = "Введите корректную сумму"
            showError = true
            return
        }

        let newAmount = min(goal.currentAmount + amount, goal.targetAmount)

        let updatedGoal = Goal(
            id: goal.id,
            name: goal.name,
            targetAmount: goal.targetAmount,
            currentAmount: newAmount,
            deadline: goal.deadline,
            currency: goal.currency,
            accountId: goal.accountId
        )

        coreDataService.updateGoal(updatedGoal)
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
    @State private var attemptCount = 0

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: authManager.biometricType == .faceID ? "faceid" : (authManager.biometricType == .touchID ? "touchid" : "lock.fill"))
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("FinanceFlow")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Защита данных")
                    .foregroundColor(.gray)
            }
            .padding()

            if authManager.isBiometricAvailable {
                VStack(spacing: 12) {
                    Button(action: {
                        authManager.authenticate()
                    }) {
                        HStack {
                            Image(systemName: authManager.biometricType == .faceID ? "faceid" : "touchid")
                            Text(authManager.biometricType == .faceID ? "Разблокировать Face ID" : "Разблокировать Touch ID")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }

                    if let error = authManager.authError {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
                .padding()
            } else {
                VStack(spacing: 12) {
                    Text("Биометрия недоступна")
                        .font(.headline)
                        .foregroundColor(.red)

                    Text("Это приложение требует Face ID или Touch ID для защиты ваших данных")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }

            Spacer()
        }
        .padding()
        .frame(maxHeight: .infinity, alignment: .top)
        .onAppear {
            if authManager.isBiometricAvailable && authManager.keychain.isBiometricEnabled() {
                authManager.authenticate()
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(CoreDataService.shared)
        .environmentObject(AuthenticationManager.shared)
}
