//
//  SpeechRecognizer.swift
//  JotMe
//
//  Created by Dan Cox on 11/5/24.
//

import Foundation
import Speech

class SpeechRecognizer: ObservableObject {
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer()
    
    @Published var transcriptText: String = "" // Live transcription text

    func startTranscribing() {
        resetSession { [weak self] in // Reset session before starting
            self?.initializeTranscribingSession() // Start transcribing after reset
        }
    }

    private func initializeTranscribingSession() {
        audioEngine = AVAudioEngine()
        request = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognizer = recognizer, recognizer.isAvailable, let audioEngine = audioEngine, let request = request else {
            print("Speech recognizer or audio engine is unavailable.")
            return
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine failed to start: \(error.localizedDescription)")
            return
        }
        
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            if let result = result {
                self?.transcriptText = result.bestTranscription.formattedString // Update transcript live
            }
            if error != nil || result?.isFinal == true {
                self?.stopTranscribing() // Stop once recognition is complete or if there's an error
            }
        }
    }

    func stopTranscribing() {
        // Ensure everything is fully stopped and cleaned up
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        recognitionTask?.cancel()

        // Dispose of resources
        audioEngine = nil
        request = nil
        recognitionTask = nil
    }
    
    // Fully reset the session to clear any potential background processes, with a slight delay
    private func resetSession(completion: @escaping () -> Void) {
        stopTranscribing()
        transcriptText = ""

        // Ensure a slight delay before starting a new session to allow cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            completion()
        }
    }
}
