import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var coreDataService: CoreDataService
    @EnvironmentObject var authManager: AuthenticationManager

    var body: some View {
        TabView {
            // Dashboard
            DashboardView()
                .tabItem {
                    Label("Главная", systemImage: "house.fill")
                }

            // Operations
            OperationsView()
                .tabItem {
                    Label("Операции", systemImage: "list.bullet")
                }

            // Budgets
            BudgetsView()
                .tabItem {
                    Label("Бюджеты", systemImage: "chart.pie")
                }

            // Settings
            SettingsView()
                .tabItem {
                    Label("Настройки", systemImage: "gear")
                }
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainTabView()
        .environmentObject(CoreDataService.shared)
        .environmentObject(AuthenticationManager.shared)
}
