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
    @State private var showToast = false
    @State private var showHistory = false
    @State private var jotUploaded = false
    @StateObject private var jotHistoryViewModel: JotHistoryViewModel

    init(authManager: AuthManager) {
        _jotHistoryViewModel = StateObject(wrappedValue: JotHistoryViewModel(authManager: authManager))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if authManager.isStartupLoading {
                    ProgressView("Checking startup...")
                } else if let message = authManager.startupMessage {
                    Text(message)
                        .foregroundColor(.blue)
                        .padding()
                }

                // Navigation link to open Jot History as a new screen
                NavigationLink(destination: JotHistory(viewModel: jotHistoryViewModel), isActive: $showHistory) {
                    Button("Jot History") {
                        showHistory = true
                    }
                    .padding()
                }

                // Main recording/re-recording button
                Button(action: {
                    isRecording.toggle()
                    if isRecording {
                        jotUploaded = false
                        speechRecognizer.transcriptText = "" // Clear existing text for re-recording
                        speechRecognizer.startTranscribing()
                    } else {
                        speechRecognizer.stopTranscribing()
                    }
                }) {
                    Text(isRecording ? "Stop" : (speechRecognizer.transcriptText.isEmpty ? "Record" : "Re-record"))
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isRecording ? Color.green : Color.red)
                        .cornerRadius(10)
                }
                .padding()

                // Editable text field for live transcribed text and send button
                HStack {
                    TextField("Transcribed text will appear here", text: $speechRecognizer.transcriptText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Button(action: {
                        let jotAPI = JotAPI(authManager: authManager)
                        jotAPI.addJot(transcribedText: speechRecognizer.transcriptText) { result in
                            switch result {
                            case .success:
                                showToast = true
                                jotUploaded = true
                                isRecording = false // Reset to "Record" after sending
                                speechRecognizer.transcriptText = "" // Clear the text field
                            case .failure(let error):
                                print("Failed to add jot: \(error.localizedDescription)")
                            }
                        }
                    }) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.blue)
                            .padding()
                    }
                }
                
                // Display checkmark if jot is successfully uploaded
                if jotUploaded {
                    HStack {
                        Text("Jot successfully uploaded")
                            .foregroundColor(.green)
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    .padding(.top)
                }
            }
            .padding()
            .toast(isShowing: $showToast, message: "Jot successfully uploaded!")
            .navigationTitle("JotMe")
        }
    }
}
