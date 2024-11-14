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
    @State private var isResetting = false // New state to track reset phase
    @State private var jotUploaded = false // Track jot upload success
    @State private var transcribedText: String = "" // Store text locally for visibility
    @State private var isSending = false // Track send status
    @FocusState private var isTextEditorFocused: Bool // Track focus on TextEditor
    @StateObject private var jotHistoryViewModel: JotHistoryViewModel

    init(authManager: AuthManager) {
        _jotHistoryViewModel = StateObject(wrappedValue: JotHistoryViewModel(authManager: authManager))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if authManager.isStartupLoading {
                    ProgressView("Checking startup...")
                } else if let message = authManager.startupMessage {
                    Text(message)
                        .foregroundColor(.blue)
                        .padding()
                }

                // Navigation links to Jot History and Reminders
                NavigationLink("Jot History", value: "jotHistory")
                    .padding()
                    .foregroundColor(.blue)
                NavigationLink("Reminders", value: "reminders")
                    .padding()
                    .foregroundColor(.blue)
                
                // Recording button
                Button(action: {
                    hideKeyboard() // Hide keyboard when recording starts
                    if !isResetting {
                        toggleRecording() // Toggle recording state
                    }
                }) {
                    Text(isResetting ? "Wait" : (isRecording ? "Stop" : (transcribedText.isEmpty ? "Record" : "Re-record")))
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isResetting ? Color.gray : (isRecording ? Color.green : Color.red))
                        .cornerRadius(10)
                }
                .padding()

                // Editable text field with send button and progress view
                HStack {
                    TextEditor(text: $transcribedText)
                        .frame(minHeight: 50, maxHeight: 150) // Expands to fit text
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .onChange(of: speechRecognizer.transcriptText) { newValue in
                            if isRecording {
                                transcribedText = newValue // Update live transcription
                            }
                        }
                        .focused($isTextEditorFocused) // Track focus state
                        .disabled(isSending) // Disable TextEditor while sending
                        .onTapGesture {
                            clearSuccessMessage() // Clear success on text editor tap
                            stopRecordingIfActive() // Stop recording if user taps the text editor
                        }

                    Button(action: {
                        clearSuccessMessage() // Clear success on send
                        stopRecordingIfActive() // Stop recording if user taps send
                        hideKeyboard()
                        isSending = true // Start sending
                        let jotAPI = JotAPI(authManager: authManager)
                        jotAPI.addJot(transcribedText: transcribedText) { result in
                            DispatchQueue.main.async {
                                isSending = false // Stop sending
                                switch result {
                                case .success:
                                    jotUploaded = true
                                    isRecording = false // Reset to "Record"
                                    transcribedText = "" // Clear after sending
                                case .failure(let error):
                                    print("Failed to add jot: \(error.localizedDescription)")
                                }
                            }
                        }
                    }) {
                        if isSending {
                            ProgressView() // Spinner while sending
                                .padding()
                        } else {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.blue)
                                .padding()
                        }
                    }
                    .disabled(isSending || transcribedText.isEmpty) // Disable while sending or if text is empty
                }
                
                // Success message with checkmark
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
            .navigationTitle("JotMe")
            .navigationDestination(for: String.self) { value in
                if value == "jotHistory" {
                    JotHistory(viewModel: jotHistoryViewModel)
                } else if value == "reminders" {
                    RemindersView(viewModel: jotHistoryViewModel)
                }
            }
            .onTapGesture {
                hideKeyboard() // Hide keyboard on tap outside TextEditor
            }
        }
    }

    // Toggle recording state
    private func toggleRecording() {
        isRecording.toggle()
        clearSuccessMessage() // Clear success on (re-)record
        if isRecording {
            transcribedText = "" // Clear for re-recording
            speechRecognizer.startTranscribing()
        } else {
            stopRecordingIfActive() // Stop recording if toggled off
        }
    }

    // Stop recording if active
    private func stopRecordingIfActive() {
        if isRecording {
            isResetting = true // Set "Wait" state during reset
            speechRecognizer.stopTranscribing()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Simulated reset delay
                isRecording = false
                isResetting = false
            }
        }
    }

    // Function to hide the keyboard
    private func hideKeyboard() {
        isTextEditorFocused = false
    }

    // Clear the success message
    private func clearSuccessMessage() {
        jotUploaded = false
    }
}
