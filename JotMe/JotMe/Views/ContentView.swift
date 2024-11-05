//
//  ContentView.swift
//  JotMe
//
//  Created by Dan Cox on 11/5/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    var body: some View {
        VStack {
            if authManager.isStartupLoading {
                // Show startup progress view
                ProgressView("Checking startup...")
            } else if let message = authManager.startupMessage {
                // Show startup message if no deep link is present
                Text(message)
                    .foregroundColor(.blue)
                    .padding()
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
