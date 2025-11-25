import SwiftUI

struct OperationsView: View {
    @EnvironmentObject var coreDataService: CoreDataService
    @State private var searchText: String = ""
    @State private var selectedType: OperationType? = nil

    var filteredOperations: [Operation] {
        var filtered = coreDataService.operations

        if let type = selectedType {
            filtered = filtered.filter { $0.type == type }
        }

        if !searchText.isEmpty {
            filtered = filtered.filter { $0.description.localizedCaseInsensitiveContains(searchText) }
        }

        return filtered
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filters
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)

                        TextField("Поиск...", text: $searchText)

                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                    // Type filters
                    HStack(spacing: 8) {
                        ForEach(OperationType.allCases, id: \.self) { type in
                            Button(action: {
                                if selectedType == type {
                                    selectedType = nil
                                } else {
                                    selectedType = type
                                }
                            }) {
                                Text(type.displayName)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedType == type ? Color.blue : Color(.systemGray6))
                                    .foregroundColor(selectedType == type ? .white : .black)
                                    .cornerRadius(8)
                            }
                        }

                        Spacer()
                    }
                }
                .padding()

                // Operations List
                List {
                    if filteredOperations.isEmpty {
                        VStack(alignment: .center, spacing: 12) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)

                            Text("Нет операций")
                                .font(.headline)

                            Text("Добавьте операцию, чтобы она появилась здесь")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(filteredOperations) { operation in
                            OperationListItemView(operation: operation)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        coreDataService.deleteOperation(operation.id)
                                    } label: {
                                        Label("Удалить", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Операции")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct OperationListItemView: View {
    @EnvironmentObject var coreDataService: CoreDataService
    let operation: Operation

    var categoryName: String {
        coreDataService.categories.first { $0.id == operation.categoryId }?.name ?? "Unknown"
    }

    var accountName: String {
        coreDataService.accounts.first { $0.id == operation.accountId }?.name ?? "Unknown"
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .center) {
                if let category = coreDataService.categories.first(where: { $0.id == operation.categoryId }) {
                    Text(category.icon)
                        .font(.title3)
                }
            }
            .frame(width: 40, height: 40)
            .background(Color(.systemGray6))
            .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(categoryName)
                    .font(.callout)
                    .fontWeight(.semibold)

                Text(operation.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.gray)

                if !operation.description.isEmpty {
                    Text(operation.description)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(operation.type == .expense ? "-" : "+") \(String(format: "%.2f", operation.amount)) \(operation.currency)")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(operation.type == .expense ? .red : .green)

                Text(accountName)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    OperationsView()
        .environmentObject(CoreDataService.shared)
}
