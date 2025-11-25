import Foundation
import Combine

class OperationsViewModel: ObservableObject {
    @Published var operations: [Operation] = []
    @Published var filteredOperations: [Operation] = []
    @Published var selectedType: OperationType? = nil
    @Published var selectedCategory: Category? = nil
    @Published var searchText: String = ""

    private var coreDataService: CoreDataService

    init(coreDataService: CoreDataService) {
        self.coreDataService = coreDataService
        self.operations = coreDataService.operations
        filterOperations()
    }

    func filterOperations() {
        var filtered = operations

        if let type = selectedType {
            filtered = filtered.filter { $0.type == type }
        }

        if let category = selectedCategory {
            filtered = filtered.filter { $0.categoryId == category.id }
        }

        if !searchText.isEmpty {
            filtered = filtered.filter { $0.description.localizedCaseInsensitiveContains(searchText) }
        }

        filteredOperations = filtered
    }

    func addOperation(_ operation: Operation, toAccount accountId: UUID) {
        coreDataService.addOperation(operation, toAccount: accountId)
        operations = coreDataService.operations
        filterOperations()
    }

    func deleteOperation(_ operationId: UUID) {
        coreDataService.deleteOperation(operationId)
        operations = coreDataService.operations
        filterOperations()
    }

    func getCategoryName(_ categoryId: UUID) -> String {
        coreDataService.categories.first { $0.id == categoryId }?.name ?? "Unknown"
    }

    func getAccountName(_ accountId: UUID) -> String {
        coreDataService.accounts.first { $0.id == accountId }?.name ?? "Unknown"
    }
}
