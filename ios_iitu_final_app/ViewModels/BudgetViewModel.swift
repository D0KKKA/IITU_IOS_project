import Foundation
import Combine

class BudgetViewModel: ObservableObject {
    @Published var budgets: [Budget] = []
    @Published var warningBudgets: [Budget] = []
    @Published var normalBudgets: [Budget] = []

    private var coreDataService: CoreDataService

    init(coreDataService: CoreDataService) {
        self.coreDataService = coreDataService
        self.budgets = coreDataService.budgets
        categorizeBudgets()
    }

    func categorizeBudgets() {
        warningBudgets = budgets.filter { $0.isWarning }
        normalBudgets = budgets.filter { !$0.isWarning && !$0.isExceeded }
    }

    func addBudget(_ budget: Budget) {
        coreDataService.addBudget(budget)
        budgets = coreDataService.budgets
        categorizeBudgets()
    }

    func getCategoryName(_ categoryId: UUID) -> String {
        coreDataService.categories.first { $0.id == categoryId }?.name ?? "Unknown"
    }

    func updateBudgetSpent() {
        // Recalculate spent amounts based on operations
        for var budget in budgets {
            let spent = coreDataService.operations
                .filter { $0.categoryId == budget.categoryId && $0.type == .expense }
                .reduce(0) { $0 + $1.amount }

            let updatedBudget = Budget(
                id: budget.id,
                categoryId: budget.categoryId,
                limit: budget.limit,
                spent: spent,
                period: budget.period,
                startDate: budget.startDate,
                currency: budget.currency
            )

            // Update in Core Data
            coreDataService.addBudget(updatedBudget)
        }

        budgets = coreDataService.budgets
        categorizeBudgets()
    }
}
