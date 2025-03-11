//
//  QandAView.swift
//  JotMe
//
//  Created by Dan Cox on 3/11/25.
//

import SwiftUI

struct QandAView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var question: String = ""
    @State private var displayText: String = "Your answer will appear here."
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Ask a Question")
                    .font(.title)
                    .padding(.top)
                
                TextEditor(text: $question)
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                
                // Centered Submit button
                HStack {
                    Spacer()
                    Button("Submit") {
                        displayText = "Fetching answer..."
                        let qaAPI = QandAAPI(authManager: authManager)
                        qaAPI.askQuestion(question: question) { result in
                            DispatchQueue.main.async {
                                switch result {
                                case .success(let response):
                                    // You now have access to response.qanda.question, response.qanda.answer, and response.qanda.createdAt
                                    displayText = response.qanda.answer
                                    // In the future, you could save response.qanda to show a history.
                                case .failure(let error):
                                    displayText = "Error: \(error.localizedDescription)"
                                }
                            }
                        }
                    }
                    Spacer()
                }
                .padding()
                
                ScrollView {
                    Text(displayText)
                        .padding()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Q&A")
        }
    }
}

