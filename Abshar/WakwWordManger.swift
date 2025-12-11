//
//  WakwWordManger.swift
//  Abshar
//
//  Created by Danyah ALbarqawi on 11/12/2025.
//

import Foundation
import Speech
import AVFoundation
internal import Combine

class WakeWordManager: NSObject, ObservableObject {
    
    @Published var isListeningForWakeWord = false
    @Published var isAssistantActive = false
    @Published var spokenText = ""
    @Published var isSpeaking = false
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ar-SA"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let synthesizer = AVSpeechSynthesizer()
    
    // Wake words - user can say any of these
    private let wakeWords = ["يا أبشر", "يا ابشر", "أبشر", "ابشر", "hey absher", "absher"]
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    // MARK: - Permissions
    
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        var speechAuthorized = false
        var micAuthorized = false
        
        let group = DispatchGroup()
        
        group.enter()
        SFSpeechRecognizer.requestAuthorization { status in
            speechAuthorized = (status == .authorized)
            group.leave()
        }
        
        group.enter()
        AVAudioApplication.requestRecordPermission { granted in
            micAuthorized = granted
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(speechAuthorized && micAuthorized)
        }
    }
    
    // MARK: - Start Listening for Wake Word
    
    func startListeningForWakeWord() {
        
        guard !isListeningForWakeWord else { return }
        
        stopEverything()
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            
            guard let recognitionRequest = recognitionRequest else { return }
            recognitionRequest.shouldReportPartialResults = true
            
            let inputNode = audioEngine.inputNode
            
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                if let result = result {
                    let spokenText = result.bestTranscription.formattedString.lowercased()
                    
                    // Check for wake word
                    for wakeWord in self.wakeWords {
                        if spokenText.contains(wakeWord.lowercased()) {
                            self.wakeWordDetected()
                            return
                        }
                    }
                }
                
                // Restart if ended without wake word
                if error != nil || (result?.isFinal ?? false) {
                    self.restartWakeWordListening()
                }
            }
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                self.recognitionRequest?.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            DispatchQueue.main.async {
                self.isListeningForWakeWord = true
            }
            
            print("🎤 Listening for wake word: يا أبشر")
            
        } catch {
            print("Error starting wake word listener: \(error)")
        }
    }
    
    private func restartWakeWordListening() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            if !self.isAssistantActive {
                self.stopEverything()
                self.startListeningForWakeWord()
            }
        }
    }
    
    // MARK: - Wake Word Detected
    
    private func wakeWordDetected() {
        print("✅ Wake word detected!")
        
        stopEverything()
        
        DispatchQueue.main.async {
            self.isAssistantActive = true
            self.isListeningForWakeWord = false
            
            // Play activation sound
            AudioServicesPlaySystemSound(1113)
            
            // Speak greeting
            self.speak("نعم، كيف أقدر أساعدك؟")
        }
        
        // Start listening for command after greeting
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.startListeningForCommand()
        }
    }
    
    // MARK: - Listen for Command
    
    func startListeningForCommand() {
        
        spokenText = ""
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            
            guard let recognitionRequest = recognitionRequest else { return }
            recognitionRequest.shouldReportPartialResults = true
            
            let inputNode = audioEngine.inputNode
            
            // Auto-stop timer
            var silenceTimer: Timer?
            
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                silenceTimer?.invalidate()
                
                if let result = result {
                    DispatchQueue.main.async {
                        self.spokenText = result.bestTranscription.formattedString
                    }
                    
                    // Auto-stop after 2 seconds of silence
                    silenceTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                        if !self.spokenText.isEmpty {
                            self.commandComplete()
                        }
                    }
                }
                
                if error != nil || (result?.isFinal ?? false) {
                    if !self.spokenText.isEmpty {
                        self.commandComplete()
                    } else {
                        self.deactivateAssistant()
                    }
                }
            }
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                self.recognitionRequest?.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            print("🎤 Listening for command...")
            
        } catch {
            print("Error starting command listener: \(error)")
        }
    }
    
    private func commandComplete() {
        stopEverything()
        
        // Notify that command is ready
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("VoiceCommandReceived"),
                object: nil,
                userInfo: ["command": self.spokenText]
            )
        }
    }
    
    // MARK: - Deactivate Assistant
    
    func deactivateAssistant() {
        stopEverything()
        
        DispatchQueue.main.async {
            self.isAssistantActive = false
            self.spokenText = ""
        }
        
        // Resume wake word listening
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.startListeningForWakeWord()
        }
    }
    
    // MARK: - Stop Everything
    
    func stopEverything() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        
        DispatchQueue.main.async {
            self.isListeningForWakeWord = false
        }
    }
    
    // MARK: - Speak
    
    func speak(_ text: String) {
        
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ar-SA")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
        
        synthesizer.speak(utterance)
    }
}

extension WakeWordManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
}
