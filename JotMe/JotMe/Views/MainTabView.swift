//
//  MainTabView.swift
//  JotMe
//
//  Created by Dan Cox on 3/11/25.
//


import SwiftUI

struct MainTabView: View {
    var authManager: AuthManager
    
    var body: some View {
        TabView {
            // Home Tab: Uses your existing ContentView.
            ContentView(authManager: authManager)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            // Q&A Tab: This is our new view.
            QandAView()
                .tabItem {
                    Image(systemName: "cloud.fill")
                    Text("Q&A")
                }
        }
    }
}
