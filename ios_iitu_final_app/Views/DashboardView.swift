import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var coreDataService: CoreDataService
    @State private var showAddOperation = false

    // Computed properties for real-time updates
    var totalBalance: Double {
        coreDataService.accounts.reduce(0) { $0 + $1.balance }
    }

    var thisWeekExpenses: Double {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return coreDataService.operations
            .filter { $0.type == .expense && $0.date >= weekAgo }
            .reduce(0) { $0 + $1.amount }
    }

    var thisWeekIncome: Double {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return coreDataService.operations
            .filter { $0.type == .income && $0.date >= weekAgo }
            .reduce(0) { $0 + $1.amount }
    }

    var recentOperations: [Operation] {
        Array(coreDataService.operations.prefix(5))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("FinanceFlow")
                            .font(.title)
                            .fontWeight(.bold)

                        Text(Date().formatted(date: .abbreviated, time: .omitted))
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    // Total Balance Card
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Общий баланс")
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                Text("\(String(format: "%.2f", totalBalance)) KZT")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }

                            Spacer()

                            Image(systemName: "wallet.pass")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }

                        Divider()

                        HStack(spacing: 16) {
                            // Income
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Доход на неделю")
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                Text("+\(String(format: "%.2f", thisWeekIncome)) KZT")
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                            }

                            Divider()

                            // Expenses
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Расход на неделю")
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                Text("-\(String(format: "%.2f", thisWeekExpenses)) KZT")
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Quick Actions
                    VStack(spacing: 12) {
                        Text("Быстрые действия")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        HStack(spacing: 12) {
                            Button(action: { showAddOperation = true }) {
                                Label("Добавить расход", systemImage: "minus.circle.fill")
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.red)
                                    .cornerRadius(8)
                            }

                            Button(action: { showAddOperation = true }) {
                                Label("Добавить доход", systemImage: "plus.circle.fill")
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.green)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Recent Operations
                    if !recentOperations.isEmpty {
                        VStack(spacing: 12) {
                            Text("Последние операции")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)

                            VStack(spacing: 8) {
                                ForEach(recentOperations) { operation in
                                    OperationRowView(operation: operation)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding(.vertical)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAddOperation) {
                AddOperationView()
                    .environmentObject(coreDataService)
            }
        }
    }
}

struct OperationRowView: View {
    @EnvironmentObject var coreDataService: CoreDataService
    let operation: Operation

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "circle.fill")
                .foregroundColor(operation.type == .expense ? .red : .green)

            VStack(alignment: .leading, spacing: 4) {
                Text(coreDataService.categories.first { $0.id == operation.categoryId }?.name ?? "Unknown")
                    .font(.callout)
                    .fontWeight(.semibold)

                Text(operation.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Text("\(operation.type == .expense ? "-" : "+") \(String(format: "%.2f", operation.amount))")
                .fontWeight(.semibold)
                .foregroundColor(operation.type == .expense ? .red : .green)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    DashboardView()
        .environmentObject(CoreDataService.shared)
}
