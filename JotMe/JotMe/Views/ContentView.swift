//
//  ContentView.swift
//  JotMe
//
//  Created by Dan Cox on 11/5/24.
//

import SwiftUI
import AVFoundation
import Speech

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var isRecording = false
    @State private var jotMessage: String? // Holds success message from API response
    @State private var jotDetails: JotDetails? // Holds jot details from API response

    var body: some View {
        VStack(spacing: 20) {
            if authManager.isStartupLoading {
                ProgressView("Checking startup...")
            } else if let message = authManager.startupMessage {
                Text(message)
                    .foregroundColor(.blue)
                    .padding()
            }

            Button(action: {
                isRecording.toggle()
                if isRecording {
                    speechRecognizer.startTranscribing()
                } else {
                    speechRecognizer.stopTranscribing()
                    let jotAPI = JotAPI(authManager: authManager)
                    jotAPI.addJot(transcribedText: speechRecognizer.transcriptText) { result in
                        switch result {
                        case .success(let response):
                            jotMessage = response.message
                            jotDetails = response.jot
                        case .failure(let error):
                            jotMessage = "Failed to add jot: \(error.localizedDescription)"
                        }
                    }
                }
            }) {
                Text(isRecording ? "Stop" : "Record")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isRecording ? Color.green : Color.red)
                    .cornerRadius(10)
            }
            .padding()

            // Display Transcribed Text
            Text(speechRecognizer.transcriptText)
                .foregroundColor(.blue)
                .padding()

            // Display API Response Message
            if let message = jotMessage {
                Text(message)
                    .foregroundColor(.green)
                    .padding()
            }

            // Display Jot Details if Available
            if let details = jotDetails {
                Text("Jot ID: \(details.id)")
                Text("Created At: \(details.created_at)")
                Text("Jot Text: \(details.jot_text)")
                    .padding()
            }
        }
        .padding()
    }
}
