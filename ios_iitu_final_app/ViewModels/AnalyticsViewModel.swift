import Foundation
import Combine

class AnalyticsViewModel: ObservableObject {
    @Published var monthlyExpenses: Double = 0
    @Published var monthlyIncome: Double = 0
    @Published var expensesByCategory: [String: Double] = [:]
    @Published var topCategories: [(String, Double)] = []

    private var coreDataService: CoreDataService

    init(coreDataService: CoreDataService) {
        self.coreDataService = coreDataService
        calculateAnalytics()
    }

    func calculateAnalytics() {
        let now = Date()
        let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: now)!

        // Monthly stats
        monthlyExpenses = coreDataService.operations
            .filter { $0.type == .expense && $0.date >= monthAgo }
            .reduce(0) { $0 + $1.amount }

        monthlyIncome = coreDataService.operations
            .filter { $0.type == .income && $0.date >= monthAgo }
            .reduce(0) { $0 + $1.amount }

        // Expenses by category
        var categoryExpenses: [String: Double] = [:]

        for operation in coreDataService.operations.filter({ $0.type == .expense && $0.date >= monthAgo }) {
            let categoryName = coreDataService.categories
                .first { $0.id == operation.categoryId }?.name ?? "Unknown"

            categoryExpenses[categoryName, default: 0] += operation.amount
        }

        expensesByCategory = categoryExpenses

        // Top categories
        topCategories = categoryExpenses
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { ($0.key, $0.value) }
    }

    func getExpenseTrend() -> [Double] {
        // Get last 12 months trend
        var monthlyTotals: [Double] = Array(repeating: 0, count: 12)

        for operation in coreDataService.operations.filter({ $0.type == .expense }) {
            let monthOffset = Calendar.current.dateComponents([.month], from: operation.date, to: Date()).month ?? 0

            if monthOffset >= 0 && monthOffset < 12 {
                monthlyTotals[12 - monthOffset - 1] += operation.amount
            }
        }

        return monthlyTotals
    }
}
