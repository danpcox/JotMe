//
//  QandAView.swift
//  JotMe
//
//  Created by Dan Cox on 3/11/25.
//


import SwiftUI

struct QandAView: View {
    @State private var question: String = ""
    @State private var answer: String = "Your answer will appear here."
    
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
                
                Button("Submit") {
                    // For now, just show a placeholder response.
                    answer = "Fetching answer for: \(question)"
                }
                .padding()
                
                ScrollView {
                    Text(answer)
                        .padding()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Q&A")
        }
    }
}
