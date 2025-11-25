import Foundation
import CoreData

// MARK: - Operation Type
enum OperationType: String, CaseIterable {
    case expense = "expense"
    case income = "income"
    case transfer = "transfer"

    var displayName: String {
        switch self {
        case .expense: return "Расход"
        case .income: return "Доход"
        case .transfer: return "Перевод"
        }
    }
}

// MARK: - Budget Period
enum BudgetPeriod: String, CaseIterable {
    case week = "week"
    case month = "month"
    case quarter = "quarter"
    case year = "year"

    var displayName: String {
        switch self {
        case .week: return "Неделя"
        case .month: return "Месяц"
        case .quarter: return "Квартал"
        case .year: return "Год"
        }
    }
}

// MARK: - Account Type
enum AccountType: String, CaseIterable {
    case cash = "cash"
    case card = "card"
    case deposit = "deposit"
    case wallet = "wallet"
    case crypto = "crypto"

    var displayName: String {
        switch self {
        case .cash: return "Наличные"
        case .card: return "Карта"
        case .deposit: return "Депозит"
        case .wallet: return "E-Кошелёк"
        case .crypto: return "Крипто"
        }
    }

    var icon: String {
        switch self {
        case .cash: return "banknote"
        case .card: return "creditcard"
        case .deposit: return "building.2"
        case .wallet: return "wallet.pass"
        case .crypto: return "bitcoinsign"
        }
    }
}

// MARK: - Category Model
struct Category: Identifiable, Hashable {
    let id: UUID
    let name: String
    let icon: String
    let color: String
    let type: OperationType
    let isCustom: Bool

    init(id: UUID = UUID(), name: String, icon: String, color: String, type: OperationType, isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.type = type
        self.isCustom = isCustom
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Category, rhs: Category) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Account Model
struct Account: Identifiable, Hashable {
    let id: UUID
    let name: String
    let balance: Double
    let currency: String
    let type: AccountType

    init(id: UUID = UUID(), name: String, balance: Double, currency: String, type: AccountType) {
        self.id = id
        self.name = name
        self.balance = balance
        self.currency = currency
        self.type = type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Account, rhs: Account) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Operation Model
struct Operation: Identifiable {
    let id: UUID
    let type: OperationType
    let amount: Double
    let currency: String
    let categoryId: UUID
    let date: Date
    let accountId: UUID
    let description: String
    let attachments: [Data]?

    init(id: UUID = UUID(),
         type: OperationType,
         amount: Double,
         currency: String,
         categoryId: UUID,
         date: Date,
         accountId: UUID,
         description: String,
         attachments: [Data]? = nil) {
        self.id = id
        self.type = type
        self.amount = amount
        self.currency = currency
        self.categoryId = categoryId
        self.date = date
        self.accountId = accountId
        self.description = description
        self.attachments = attachments
    }
}

// MARK: - Budget Model
struct Budget: Identifiable {
    let id: UUID
    let categoryId: UUID
    let limit: Double
    let spent: Double
    let period: BudgetPeriod
    let startDate: Date
    let currency: String

    init(id: UUID = UUID(),
         categoryId: UUID,
         limit: Double,
         spent: Double = 0,
         period: BudgetPeriod,
         startDate: Date,
         currency: String) {
        self.id = id
        self.categoryId = categoryId
        self.limit = limit
        self.spent = spent
        self.period = period
        self.startDate = startDate
        self.currency = currency
    }

    var percentage: Double {
        guard limit > 0 else { return 0 }
        return min((spent / limit) * 100, 100)
    }

    var isExceeded: Bool {
        spent > limit
    }

    var isWarning: Bool {
        percentage >= 80 && !isExceeded
    }
}

// MARK: - Goal Model
struct Goal: Identifiable {
    let id: UUID
    let name: String
    let targetAmount: Double
    let currentAmount: Double
    let deadline: Date
    let currency: String
    let accountId: UUID

    init(id: UUID = UUID(),
         name: String,
         targetAmount: Double,
         currentAmount: Double = 0,
         deadline: Date,
         currency: String,
         accountId: UUID) {
        self.id = id
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.deadline = deadline
        self.currency = currency
        self.accountId = accountId
    }

    var percentage: Double {
        guard targetAmount > 0 else { return 0 }
        return min((currentAmount / targetAmount) * 100, 100)
    }

    var daysRemaining: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: deadline)
        return max(components.day ?? 0, 0)
    }
}
