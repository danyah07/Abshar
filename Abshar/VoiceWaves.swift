//
//  VoiceWaves.swift
//  Abshar
//
//  Created by Danyah ALbarqawi on 11/12/2025.
//

import SwiftUI

// MARK: - Voice Wave View
struct VoiceWaveView: View {
    
    @Binding var isActive: Bool
    @Binding var isListening: Bool
    @Binding var isSpeaking: Bool
    
    @State private var waveAmplitudes: [CGFloat] = Array(repeating: 0.3, count: 20)
    @State private var timer: Timer?
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<20, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.absherMint, Color.absherMint.opacity(0.6)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 4, height: waveAmplitudes[index] * 50)
            }
        }
        .frame(height: 50)
        .onAppear {
            startAnimating()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                startAnimating()
            } else {
                timer?.invalidate()
            }
        }
    }
    
    func startAnimating() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.1)) {
                for i in 0..<waveAmplitudes.count {
                    if isListening || isSpeaking {
                        waveAmplitudes[i] = CGFloat.random(in: 0.3...1.0)
                    } else {
                        waveAmplitudes[i] = CGFloat.random(in: 0.2...0.4)
                    }
                }
            }
        }
    }
}
