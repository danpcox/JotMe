//
//  JotHistory.swift
//  JotMe
//
//  Created by Dan Cox on 11/5/24.
//

import SwiftUI

struct JotHistory: View {
    @ObservedObject var viewModel: JotHistoryViewModel
    @State private var refreshing = false // Track refresh state

    var body: some View {
        List { // Use List directly in the NavigationView without VStack
            if (viewModel.loading || refreshing) && viewModel.jots.isEmpty {
                ProgressView("Refreshing jots...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if viewModel.jots.isEmpty {
                Text("No jots found.")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(viewModel.jots.sorted(by: { $0.created_at > $1.created_at })) { jot in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(jot.jot_text)
                            .font(.body)
                        Text(jot.created_at)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .refreshable {
            if !refreshing {
                refreshing = true
                viewModel.jots = [] // Clear list during refresh
                viewModel.refreshJotHistory() // Refresh the data
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    refreshing = false // Reset refreshing after completion
                }
            }
        }
        .navigationTitle("Jot History") // Apply title directly to List
        .navigationBarTitleDisplayMode(.inline) // Set to inline for reduced spacing
        .onAppear {
            viewModel.fetchJotHistoryIfNeeded() // Fetch only if needed
        }
    }
}