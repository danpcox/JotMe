//
//  SpeechRecognizer.swift
//  JotMe
//
//  Created by Dan Cox on 11/5/24.
//

import AVFoundation
import Speech
import SwiftUI

class SpeechRecognizer: ObservableObject {
    @Published var transcriptText: String = ""
    private var audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer()

    init() {
        // Request speech recognition permission
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                print("Speech recognition authorized")
            default:
                print("Speech recognition not authorized")
            }
        }
    }

    func startTranscribing() {
        // Ensure previous task is canceled
        stopTranscribing()
        
        // Reset transcribed text for a new session
        transcriptText = ""
        
        // Prepare the new audio request
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else { return }
        request.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.removeTap(onBus: 0) // Clear previous taps
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        
        // Start the audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine couldn't start: \(error)")
        }
        
        // Start a new recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self.transcriptText = result.bestTranscription.formattedString
                }
            }
            if error != nil || (result?.isFinal ?? false) {
                self.stopTranscribing()
            }
        }
    }

    func stopTranscribing() {
        // Stop the audio engine and remove the tap
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // Cancel any ongoing recognition task and clear the request
        recognitionTask?.cancel()
        recognitionTask = nil
        request = nil
    }
}
