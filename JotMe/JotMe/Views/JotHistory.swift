//
//  JotHistory.swift
//  JotMe
//
//  Created by Dan Cox on 11/5/24.
//

import SwiftUI

struct JotHistory: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var jots: [JotDetails] = [] // Holds the retrieved jots
    @State private var loading = true // Track loading state
    @State private var errorMessage: String? // Display error messages if fetching fails

    var body: some View {
        NavigationView {
            VStack {
                if loading {
                    ProgressView("Loading jots...")
                        .padding()
                } else if let error = errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                } else {
                    List(jots.sorted(by: { $0.created_at > $1.created_at })) { jot in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(jot.jot_text)
                                .font(.body)
                            Text(jot.created_at)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Jot History")
            .onAppear(perform: fetchJotHistory)
        }
    }

    // Fetch jot history from API
    private func fetchJotHistory() {
        let jotAPI = JotAPI(authManager: authManager)
        jotAPI.getJotHistory { result in
            DispatchQueue.main.async {
                loading = false
                switch result {
                case .success(let jots):
                    self.jots = jots
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    JotHistory().environmentObject(AuthManager())
}
