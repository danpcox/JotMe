//
//  JotMeApp.swift
//  JotMe
//
//  Created by Dan Cox on 11/5/24.
//

import SwiftUI

@main
struct JotMeApp: App {
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                // Instead of ContentView, use MainTabView for bottom navigation.
                MainTabView(authManager: authManager)
                    .environmentObject(authManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
}
