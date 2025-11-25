import Foundation
import Combine

class DashboardViewModel: ObservableObject {
    @Published var totalBalance: Double = 0
    @Published var thisWeekExpenses: Double = 0
    @Published var thisWeekIncome: Double = 0
    @Published var recentOperations: [Operation] = []

    private var coreDataService: CoreDataService

    init(coreDataService: CoreDataService) {
        self.coreDataService = coreDataService
        updateDashboard()
    }

    func updateDashboard() {
        // Calculate total balance
        totalBalance = coreDataService.accounts.reduce(0) { $0 + $1.balance }

        // Calculate this week stats
        let now = Date()
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!

        thisWeekExpenses = coreDataService.operations
            .filter { $0.type == .expense && $0.date >= weekAgo }
            .reduce(0) { $0 + $1.amount }

        thisWeekIncome = coreDataService.operations
            .filter { $0.type == .income && $0.date >= weekAgo }
            .reduce(0) { $0 + $1.amount }

        // Get recent operations (last 5)
        recentOperations = Array(coreDataService.operations.prefix(5))
    }
}
