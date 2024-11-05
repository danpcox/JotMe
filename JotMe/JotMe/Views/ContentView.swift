//
//  ContentView.swift
//  JotMe
//
//  Created by Dan Cox on 11/5/24.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var transcriptText: String = "" // Holds the transcribed text
    private var dingSoundPlayer: AVAudioPlayer? // Audio player for the "ding" sound

    init() {
        // Load the "ding" sound from the app bundle
        if let soundURL = Bundle.main.url(forResource: "ding", withExtension: "mp3") {
            do {
                dingSoundPlayer = try AVAudioPlayer(contentsOf: soundURL)
            } catch {
                print("Error creating AVAudioPlayer: \(error)")
            }
        } else {
            print("Error loading sound file")
        }
    }

    // Function to play the "ding" sound
    private func playDingSound() {
        dingSoundPlayer?.play()
    }

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

            // Big Red Button
            Button(action: {
                playDingSound() // Play the "ding" sound
                print("Button tapped") // Placeholder for recording action
            }) {
                Text("Record")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(10)
            }
            .padding()

            // Display Transcribed Text
            Text(transcriptText)
                .foregroundColor(.blue)
                .padding()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
