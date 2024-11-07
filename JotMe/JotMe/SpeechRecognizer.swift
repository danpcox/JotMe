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
        audioEngine = AVAudioEngine()
        request = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognizer = recognizer, recognizer.isAvailable, let audioEngine = audioEngine, let request = request else {
            return
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        
        audioEngine.prepare()
        try? audioEngine.start()
        
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            if let result = result {
                // Update the transcript text in real time
                self?.transcriptText = result.bestTranscription.formattedString
            }
            if error != nil || result?.isFinal == true {
                self?.stopTranscribing()
            }
        }
    }

    func stopTranscribing() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        recognitionTask?.cancel()
        
        audioEngine = nil
        request = nil
        recognitionTask = nil
    }
}
