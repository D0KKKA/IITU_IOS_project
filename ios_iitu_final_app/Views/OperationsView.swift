import SwiftUI

struct OperationsView: View {
    @EnvironmentObject var coreDataService: CoreDataService
    @StateObject private var viewModel: OperationsViewModel

    init() {
        _viewModel = StateObject(wrappedValue: OperationsViewModel(coreDataService: CoreDataService.shared))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filters
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)

                        TextField("Поиск...", text: $viewModel.searchText)
                            .onChange(of: viewModel.searchText) { _ in
                                viewModel.filterOperations()
                            }

                        if !viewModel.searchText.isEmpty {
                            Button(action: {
                                viewModel.searchText = ""
                                viewModel.filterOperations()
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
                                if viewModel.selectedType == type {
                                    viewModel.selectedType = nil
                                } else {
                                    viewModel.selectedType = type
                                }
                                viewModel.filterOperations()
                            }) {
                                Text(type.displayName)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(viewModel.selectedType == type ? Color.blue : Color(.systemGray6))
                                    .foregroundColor(viewModel.selectedType == type ? .white : .black)
                                    .cornerRadius(8)
                            }
                        }

                        Spacer()
                    }
                }
                .padding()

                // Operations List
                List {
                    if viewModel.filteredOperations.isEmpty {
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
                        ForEach(viewModel.filteredOperations) { operation in
                            OperationListItemView(operation: operation, viewModel: viewModel)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        viewModel.deleteOperation(operation.id)
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
    let viewModel: OperationsViewModel

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
                Text(viewModel.getCategoryName(operation.categoryId))
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

                Text(viewModel.getAccountName(operation.accountId))
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
