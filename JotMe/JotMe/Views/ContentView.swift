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
    @StateObject private var jotHistoryViewModel: JotHistoryViewModel // ViewModel for JotHistory

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

                Button(action: {
                    isRecording.toggle()
                    if isRecording {
                        jotUploaded = false
                        speechRecognizer.startTranscribing()
                    } else {
                        speechRecognizer.stopTranscribing()
                        let jotAPI = JotAPI(authManager: authManager)
                        jotAPI.addJot(transcribedText: speechRecognizer.transcriptText) { result in
                            switch result {
                            case .success:
                                showToast = true
                                jotUploaded = true
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
                        .background(isRecording ? Color.green : Color.red)
                        .cornerRadius(10)
                }
                .padding()

                HStack {
                    Text(speechRecognizer.transcriptText)
                        .foregroundColor(.blue)
                        .padding()
                    if jotUploaded {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            .toast(isShowing: $showToast, message: "Jot successfully uploaded!")
            .navigationTitle("JotMe")
        }
    }
}
