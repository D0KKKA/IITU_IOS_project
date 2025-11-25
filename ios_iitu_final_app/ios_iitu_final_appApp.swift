//
//  ios_iitu_final_appApp.swift
//  ios_iitu_final_app
//
//  Created by Кукурекин  Данил on 25.11.2025.
//

import SwiftUI

@main
struct ios_iitu_final_appApp: App {
    @StateObject private var coreDataService = CoreDataService.shared
    @StateObject private var authManager = AuthenticationManager.shared

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(coreDataService)
                    .environmentObject(authManager)
            } else {
                AuthenticationView()
                    .environmentObject(authManager)
            }
        }
    }
}
