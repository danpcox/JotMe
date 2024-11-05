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
    @StateObject private var speechRecognizer = SpeechRecognizer() // Speech recognizer instance
    @State private var isRecording = false // Track recording state

    var body: some View {
        VStack(spacing: 20) {
            // Display the startup message if available
            if authManager.isStartupLoading {
                ProgressView("Checking startup...")
            } else if let message = authManager.startupMessage {
                Text(message)
                    .foregroundColor(.blue)
                    .padding()
            }

            // Toggle Recording Button
            Button(action: {
                isRecording.toggle() // Toggle recording state
                if isRecording {
                    speechRecognizer.startTranscribing() // Start transcribing
                } else {
                    speechRecognizer.stopTranscribing() // Stop transcribing
                    let jotAPI = JotAPI(authManager: authManager)
                    jotAPI.addJot(transcribedText: speechRecognizer.transcriptText) { result in
                        switch result {
                        case .success:
                            print("Jot successfully added to server.")
                        case .failure(let error):
                            print("Failed to add jot: \(error.localizedDescription)")
                        }
                    }
                }
            }) {
                Text(isRecording ? "Stop" : "Record")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isRecording ? Color.green : Color.red) // Green while recording, red otherwise
                    .cornerRadius(10)
            }
            .padding()

            // Display Transcribed Text
            Text(speechRecognizer.transcriptText)
                .foregroundColor(.blue)
                .padding()
        }
        .padding()
    }
 }


#Preview {
    ContentView()
}
