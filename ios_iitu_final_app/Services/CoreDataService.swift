import Foundation
import CoreData
import Combine

class CoreDataService: NSObject, ObservableObject {
    static let shared = CoreDataService()

    let container: NSPersistentContainer
    @Published var accounts: [Account] = []
    @Published var operations: [Operation] = []
    @Published var categories: [Category] = []
    @Published var budgets: [Budget] = []
    @Published var goals: [Goal] = []

    override init() {
        container = NSPersistentContainer(name: "FinanceFlow")

        container.loadPersistentStores { _, error in
            if let error = error {
                print("Core Data error: \(error.localizedDescription)")
            }
        }

        super.init()
        loadDefaultCategories()
        loadAllData()
    }

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    // MARK: - Save
    func save() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
                loadAllData()
            } catch {
                print("Save error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Load All Data
    func loadAllData() {
        loadAccounts()
        loadOperations()
        loadCategories()
        loadBudgets()
        loadGoals()
    }

    // MARK: - Accounts
    func loadAccounts() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "AccountEntity")

        do {
            let results = try viewContext.fetch(request) as? [NSManagedObject] ?? []

            accounts = results.compactMap { obj in
                guard let name = obj.value(forKey: "name") as? String,
                      let balance = obj.value(forKey: "balance") as? Double,
                      let currency = obj.value(forKey: "currency") as? String,
                      let type = obj.value(forKey: "type") as? String,
                      let idStr = obj.value(forKey: "id") as? String,
                      let id = UUID(uuidString: idStr),
                      let accountType = AccountType(rawValue: type) else {
                    return nil
                }

                return Account(id: id, name: name, balance: balance, currency: currency, type: accountType)
            }
        } catch {
            print("Load accounts error: \(error.localizedDescription)")
        }
    }

    func addAccount(_ account: Account) {
        guard let entity = NSEntityDescription.entity(forEntityName: "AccountEntity", in: viewContext) else {
            print("Failed to create AccountEntity")
            return
        }
        let newAccount = NSManagedObject(entity: entity, insertInto: viewContext)

        newAccount.setValue(account.id.uuidString, forKey: "id")
        newAccount.setValue(account.name, forKey: "name")
        newAccount.setValue(account.balance, forKey: "balance")
        newAccount.setValue(account.currency, forKey: "currency")
        newAccount.setValue(account.type.rawValue, forKey: "type")

        save()
    }

    func updateAccount(_ account: Account) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "AccountEntity")
        request.predicate = NSPredicate(format: "id == %@", account.id.uuidString)

        do {
            if let result = try viewContext.fetch(request).first as? NSManagedObject {
                result.setValue(account.balance, forKey: "balance")
                result.setValue(account.name, forKey: "name")
                save()
            }
        } catch {
            print("Update account error: \(error.localizedDescription)")
        }
    }

    func deleteAccount(_ accountId: UUID) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "AccountEntity")
        request.predicate = NSPredicate(format: "id == %@", accountId.uuidString)

        do {
            if let result = try viewContext.fetch(request).first as? NSManagedObject {
                viewContext.delete(result)
                save()
            }
        } catch {
            print("Delete account error: \(error.localizedDescription)")
        }
    }

    // MARK: - Operations
    func loadOperations() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "OperationEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        do {
            let results = try viewContext.fetch(request) as? [NSManagedObject] ?? []

            operations = results.compactMap { obj in
                guard let typeStr = obj.value(forKey: "type") as? String,
                      let type = OperationType(rawValue: typeStr),
                      let amount = obj.value(forKey: "amount") as? Double,
                      let currency = obj.value(forKey: "currency") as? String,
                      let categoryIdStr = obj.value(forKey: "categoryId") as? String,
                      let categoryId = UUID(uuidString: categoryIdStr),
                      let date = obj.value(forKey: "date") as? Date,
                      let accountIdStr = obj.value(forKey: "accountId") as? String,
                      let accountId = UUID(uuidString: accountIdStr),
                      let idStr = obj.value(forKey: "id") as? String,
                      let id = UUID(uuidString: idStr),
                      let opDescription = obj.value(forKey: "operationDescription") as? String else {
                    return nil
                }

                return Operation(id: id,
                               type: type,
                               amount: amount,
                               currency: currency,
                               categoryId: categoryId,
                               date: date,
                               accountId: accountId,
                               description: opDescription)
            }
        } catch {
            print("Load operations error: \(error.localizedDescription)")
        }
    }

    func addOperation(_ operation: Operation, toAccount accountId: UUID) {
        guard let entity = NSEntityDescription.entity(forEntityName: "OperationEntity", in: viewContext) else {
            print("Failed to create OperationEntity")
            return
        }
        let newOp = NSManagedObject(entity: entity, insertInto: viewContext)

        newOp.setValue(operation.id.uuidString, forKey: "id")
        newOp.setValue(operation.type.rawValue, forKey: "type")
        newOp.setValue(operation.amount, forKey: "amount")
        newOp.setValue(operation.currency, forKey: "currency")
        newOp.setValue(operation.categoryId.uuidString, forKey: "categoryId")
        newOp.setValue(operation.date, forKey: "date")
        newOp.setValue(operation.accountId.uuidString, forKey: "accountId")
        newOp.setValue(operation.description, forKey: "operationDescription")

        // Update account balance
        if let account = accounts.first(where: { $0.id == accountId }) {
            var updatedBalance = account.balance

            switch operation.type {
            case .expense:
                updatedBalance -= operation.amount
            case .income:
                updatedBalance += operation.amount
            case .transfer:
                updatedBalance -= operation.amount
            }

            let updatedAccount = Account(id: account.id,
                                       name: account.name,
                                       balance: updatedBalance,
                                       currency: account.currency,
                                       type: account.type)
            updateAccount(updatedAccount)
        }

        save()
    }

    func deleteOperation(_ operationId: UUID) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "OperationEntity")
        request.predicate = NSPredicate(format: "id == %@", operationId.uuidString)

        do {
            if let result = try viewContext.fetch(request).first as? NSManagedObject {
                viewContext.delete(result)
                save()
            }
        } catch {
            print("Delete operation error: \(error.localizedDescription)")
        }
    }

    // MARK: - Categories
    func loadCategories() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CategoryEntity")

        do {
            let results = try viewContext.fetch(request) as? [NSManagedObject] ?? []

            categories = results.compactMap { obj in
                guard let name = obj.value(forKey: "name") as? String,
                      let icon = obj.value(forKey: "icon") as? String,
                      let color = obj.value(forKey: "color") as? String,
                      let typeStr = obj.value(forKey: "type") as? String,
                      let type = OperationType(rawValue: typeStr),
                      let idStr = obj.value(forKey: "id") as? String,
                      let id = UUID(uuidString: idStr),
                      let isCustom = obj.value(forKey: "isCustom") as? Bool else {
                    return nil
                }

                return Category(id: id, name: name, icon: icon, color: color, type: type, isCustom: isCustom)
            }
        } catch {
            print("Load categories error: \(error.localizedDescription)")
        }
    }

    func addCategory(_ category: Category) {
        guard let entity = NSEntityDescription.entity(forEntityName: "CategoryEntity", in: viewContext) else {
            print("Failed to create CategoryEntity")
            return
        }
        let newCategory = NSManagedObject(entity: entity, insertInto: viewContext)

        newCategory.setValue(category.id.uuidString, forKey: "id")
        newCategory.setValue(category.name, forKey: "name")
        newCategory.setValue(category.icon, forKey: "icon")
        newCategory.setValue(category.color, forKey: "color")
        newCategory.setValue(category.type.rawValue, forKey: "type")
        newCategory.setValue(category.isCustom, forKey: "isCustom")

        save()
    }

    func deleteCategory(_ categoryId: UUID) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CategoryEntity")
        request.predicate = NSPredicate(format: "id == %@", categoryId.uuidString)

        do {
            if let result = try viewContext.fetch(request).first as? NSManagedObject {
                viewContext.delete(result)
                save()
            }
        } catch {
            print("Delete category error: \(error.localizedDescription)")
        }
    }

    // MARK: - Budgets
    func loadBudgets() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "BudgetEntity")

        do {
            let results = try viewContext.fetch(request) as? [NSManagedObject] ?? []

            budgets = results.compactMap { obj in
                guard let limit = obj.value(forKey: "limit") as? Double,
                      let spent = obj.value(forKey: "spent") as? Double,
                      let periodStr = obj.value(forKey: "period") as? String,
                      let period = BudgetPeriod(rawValue: periodStr),
                      let startDate = obj.value(forKey: "startDate") as? Date,
                      let currency = obj.value(forKey: "currency") as? String,
                      let categoryIdStr = obj.value(forKey: "categoryId") as? String,
                      let categoryId = UUID(uuidString: categoryIdStr),
                      let idStr = obj.value(forKey: "id") as? String,
                      let id = UUID(uuidString: idStr) else {
                    return nil
                }

                return Budget(id: id, categoryId: categoryId, limit: limit, spent: spent, period: period, startDate: startDate, currency: currency)
            }
        } catch {
            print("Load budgets error: \(error.localizedDescription)")
        }
    }

    func addBudget(_ budget: Budget) {
        guard let entity = NSEntityDescription.entity(forEntityName: "BudgetEntity", in: viewContext) else {
            print("Failed to create BudgetEntity")
            return
        }
        let newBudget = NSManagedObject(entity: entity, insertInto: viewContext)

        newBudget.setValue(budget.id.uuidString, forKey: "id")
        newBudget.setValue(budget.categoryId.uuidString, forKey: "categoryId")
        newBudget.setValue(budget.limit, forKey: "limit")
        newBudget.setValue(budget.spent, forKey: "spent")
        newBudget.setValue(budget.period.rawValue, forKey: "period")
        newBudget.setValue(budget.startDate, forKey: "startDate")
        newBudget.setValue(budget.currency, forKey: "currency")

        save()
    }

    // MARK: - Goals
    func loadGoals() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "GoalEntity")

        do {
            let results = try viewContext.fetch(request) as? [NSManagedObject] ?? []

            goals = results.compactMap { obj in
                guard let name = obj.value(forKey: "name") as? String,
                      let targetAmount = obj.value(forKey: "targetAmount") as? Double,
                      let currentAmount = obj.value(forKey: "currentAmount") as? Double,
                      let deadline = obj.value(forKey: "deadline") as? Date,
                      let currency = obj.value(forKey: "currency") as? String,
                      let accountIdStr = obj.value(forKey: "accountId") as? String,
                      let accountId = UUID(uuidString: accountIdStr),
                      let idStr = obj.value(forKey: "id") as? String,
                      let id = UUID(uuidString: idStr) else {
                    return nil
                }

                return Goal(id: id, name: name, targetAmount: targetAmount, currentAmount: currentAmount, deadline: deadline, currency: currency, accountId: accountId)
            }
        } catch {
            print("Load goals error: \(error.localizedDescription)")
        }
    }

    func addGoal(_ goal: Goal) {
        guard let entity = NSEntityDescription.entity(forEntityName: "GoalEntity", in: viewContext) else {
            print("Failed to create GoalEntity")
            return
        }
        let newGoal = NSManagedObject(entity: entity, insertInto: viewContext)

        newGoal.setValue(goal.id.uuidString, forKey: "id")
        newGoal.setValue(goal.name, forKey: "name")
        newGoal.setValue(goal.targetAmount, forKey: "targetAmount")
        newGoal.setValue(goal.currentAmount, forKey: "currentAmount")
        newGoal.setValue(goal.deadline, forKey: "deadline")
        newGoal.setValue(goal.currency, forKey: "currency")
        newGoal.setValue(goal.accountId.uuidString, forKey: "accountId")

        save()
    }

    // MARK: - Default Categories
    private func loadDefaultCategories() {
        // Check if categories already exist
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CategoryEntity")

        do {
            let count = try viewContext.count(for: request)
            if count > 0 {
                return
            }
        } catch {
            print("Error checking categories: \(error.localizedDescription)")
        }

        // Create default categories
        let defaultCategories: [Category] = [
            // Expenses
            Category(name: "Еда", icon: "🍔", color: "FF6B6B", type: .expense),
            Category(name: "Транспорт", icon: "🚗", color: "4ECDC4", type: .expense),
            Category(name: "Жилье", icon: "🏠", color: "95E1D3", type: .expense),
            Category(name: "Здоровье", icon: "💊", color: "FFB6B9", type: .expense),
            Category(name: "Развлечения", icon: "🎬", color: "C7CEEA", type: .expense),
            Category(name: "Подписки", icon: "📱", color: "B5EAD7", type: .expense),
            Category(name: "Покупки", icon: "🛍️", color: "FFDAC1", type: .expense),
            Category(name: "Образование", icon: "📚", color: "E0BBE4", type: .expense),
            Category(name: "Коммунальные", icon: "⚡", color: "D4F1F4", type: .expense),
            Category(name: "Прочее", icon: "📌", color: "CCCCCC", type: .expense),

            // Income
            Category(name: "Зарплата", icon: "💼", color: "91D1BA", type: .income),
            Category(name: "Фриланс", icon: "💻", color: "88CCEE", type: .income),
            Category(name: "Подарки", icon: "🎁", color: "FFDDC1", type: .income),
            Category(name: "Дивиденды", icon: "📈", color: "B4E7FF", type: .income),
            Category(name: "Прочий доход", icon: "💰", color: "FFE5B4", type: .income),
        ]

        for category in defaultCategories {
            addCategory(category)
        }
    }
}
