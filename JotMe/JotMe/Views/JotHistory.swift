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
        List {
            // Display loading, error, or no data messages
            if (viewModel.loading || refreshing) && viewModel.jots.isEmpty && viewModel.todos.isEmpty {
                ProgressView("Refreshing data...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if viewModel.jots.isEmpty && viewModel.todos.isEmpty {
                Text("No jots or todos found.")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                // Section for Jots
                Section(header: Text("Jots")) {
                    ForEach(viewModel.jots.sorted(by: { $0.createdAt > $1.createdAt })) { jot in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(jot.jotText)
                                .font(.body)
                            Text(jot.createdAt)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Section for Todos
                Section(header: Text("Todos")) {
                    ForEach(viewModel.todos.sorted(by: { $0.dueDate ?? "" < $1.dueDate ?? "" })) { todo in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(todo.todoText)
                                .font(.body)
                            if let dueDate = todo.dueDate {
                                Text("Due: \(dueDate)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .refreshable {
            if !refreshing {
                refreshing = true
                viewModel.jots = [] // Clear list during refresh
                viewModel.todos = [] // Clear todos during refresh
                viewModel.refreshJotHistory() // Refresh the data
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    refreshing = false // Reset refreshing after completion
                }
            }
        }
        .navigationTitle("Jot History")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchJotHistoryIfNeeded() // Fetch only if needed
        }
    }
}
