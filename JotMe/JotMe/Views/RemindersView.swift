//
//  RemindersView.swift
//  JotMe
//
//  Created by Dan Cox on 11/7/24.
//

import SwiftUI

struct RemindersView: View {
    @ObservedObject var viewModel: JotHistoryViewModel
    @State private var refreshing = false // Track refresh state
    @State private var showCompletionToast = false // Show toast on completion
    @State private var selectedTodoID: Int? // Track selected reminder for row highlight

    var body: some View {
        List {
            // Display loading, error, or no reminders messages
            if (viewModel.loading || refreshing) && viewModel.todos.isEmpty {
                ProgressView("Refreshing reminders...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if viewModel.todos.isEmpty {
                Text("No reminders found.")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                // Section for Reminders (Todos)
                ForEach(viewModel.todos.sorted(by: { $0.dueDate ?? "" < $1.dueDate ?? "" })) { todo in
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(todo.todoText)
                                .font(.body)
                            if let dueDate = todo.dueDate {
                                Text("Due: \(dueDate)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        Spacer()
                        // Checkbox to mark as completed
                        Button(action: {
                            markAsCompleted(todo)
                        }) {
                            Image(systemName: "square") // Checkbox icon
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle()) // Make button tap independent of row
                    }
                    .padding(.vertical, 4)
                    .background(selectedTodoID == todo.id ? Color.gray.opacity(0.2) : Color.clear) // Highlight selected row
                    .onTapGesture {
                        selectedTodoID = todo.id
                    }
                }
            }
        }
        .refreshable {
            if !refreshing {
                refreshing = true
                viewModel.refreshJotHistory() // Always refresh the data
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    refreshing = false // Reset refreshing after completion
                }
            }
        }
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Fetch data only if it's the first load
            viewModel.fetchJotHistoryIfNeeded()
        }
        .toast(isShowing: $showCompletionToast, message: "Completed Reminder")
    }
    
    // Mark a reminder as completed, show toast, and remove from the local list
    private func markAsCompleted(_ todo: Todo) {
        if let index = viewModel.todos.firstIndex(where: { $0.id == todo.id }) {
            viewModel.todos.remove(at: index) // Remove from list
            showCompletionToast = true // Show completion toast
        }
    }
}
