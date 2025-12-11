//
//  absharAI.swift
//  Abshar
//
//  Created by Danyah ALbarqawi on 11/12/2025.
//

import SwiftUI
internal import Combine
import AVFoundation




struct ContentView: View {
    
    @StateObject private var wakeWordManager = WakeWordManager()
    @StateObject private var navigator = AppNavigator()
    @State private var aiResponse = ""
    @State private var isProcessing = false
    @State private var showAssistant = false
    
    let ai = AbsherAI()
    
    var body: some View {
        ZStack {
            Color.absherBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Content based on current screen
                switch navigator.currentScreen {
                case .home:
                    HomeView(navigator: navigator)
                case .services:
                    ServicesView(navigator: navigator)
                default:
                    ServiceDetailView(screen: navigator.currentScreen, navigator: navigator)
                }
                
                // Bottom Tab Bar
                bottomTabBar
            }
            
            // Wake Word Indicator
            if !showAssistant {
                VStack {
                    Spacer()
                    HStack {
                        wakeWordButton
                            .padding(.leading, 16)
                            .padding(.bottom, 92)
                        Spacer()
                    }
                }
            }
            
            // Voice Assistant Bar
            VStack {
                Spacer()
                if showAssistant {
                    voiceAssistantBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showAssistant)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear {
            setupWakeWord()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("VoiceCommandReceived"))) { notification in
            if let command = notification.userInfo?["command"] as? String {
                processVoiceCommand(command)
            }
        }
        .onChange(of: wakeWordManager.isAssistantActive) { _, newValue in
            withAnimation {
                showAssistant = newValue
            }
        }
    }
    
    // MARK: - Setup
    
    func setupWakeWord() {
        wakeWordManager.requestPermissions { granted in
            if granted {
                wakeWordManager.startListeningForWakeWord()
            }
        }
    }
    
    // MARK: - Wake Word Button
    
    var wakeWordButton: some View {
        Button(action: manualActivate) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.black)
            }
            .frame(width: 56, height: 56)
            .background(Color.absherMint)
            .clipShape(Circle())
            .overlay(
                // Listening indicator
                Circle()
                    .fill(wakeWordManager.isListeningForWakeWord ? Color.green : Color.gray)
                    .frame(width: 12, height: 12)
                    .offset(x: 18, y: -18)
            )
        }
    }
    
    func manualActivate() {
        wakeWordManager.stopEverything()
        withAnimation {
            showAssistant = true
        }
        wakeWordManager.isAssistantActive = true
        wakeWordManager.speak("نعم، كيف أقدر أساعدك؟")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            wakeWordManager.startListeningForCommand()
        }
    }
    
    // MARK: - Voice Assistant Bar
    
    var voiceAssistantBar: some View {
        VStack(spacing: 12) {
            // Drag Indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.5))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
            
            // Voice Waves
            VoiceWaveView(
                isActive: $showAssistant,
                isListening: .constant(!wakeWordManager.isSpeaking && !isProcessing),
                isSpeaking: $wakeWordManager.isSpeaking
            )
            .frame(height: 50)
            .padding(.horizontal, 30)
            
            // Response Text
            if !aiResponse.isEmpty {
                Text(aiResponse)
                    .font(.absher(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .lineLimit(3)
            }
            
            // Spoken Text
            if !wakeWordManager.spokenText.isEmpty && aiResponse.isEmpty {
                Text(wakeWordManager.spokenText)
                    .font(.absher(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            // Status
            HStack(spacing: 8) {
                Circle()
                    .fill(getStatusColor())
                    .frame(width: 8, height: 8)
                
                Text(getStatusText())
                    .font(.absher(size: 14))
                    .foregroundColor(.gray)
            }
            
            // Close Button
            Button(action: {
                withAnimation {
                    showAssistant = false
                    aiResponse = ""
                    wakeWordManager.deactivateAssistant()
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 15)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.absherCard)
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: -5)
        )
        .padding(.horizontal, 10)
        .padding(.bottom, 70)
    }
    
    func getStatusText() -> String {
        if isProcessing { return "جاري المعالجة..." }
        if wakeWordManager.isSpeaking { return "جاري الرد..." }
        if !wakeWordManager.spokenText.isEmpty { return "سمعتك..." }
        return "جاري الاستماع... قل أمرك"
    }
    
    func getStatusColor() -> Color {
        if isProcessing { return .orange }
        if wakeWordManager.isSpeaking { return .blue }
        return .green
    }
    
    // MARK: - Bottom Tab Bar
    
    var bottomTabBar: some View {
        VStack(spacing: 0) {
            Divider().background(Color.black.opacity(0.5))
            
            HStack {
                TabItem(icon: "square.grid.2x2", title: "خدمات أخرى", isActive: false)
                TabItem(icon: "person.2.fill", title: "عمالتي", isActive: false)
                TabItem(icon: "person.3.fill", title: "عائلتي", isActive: false)
                TabItem(icon: "person.crop.circle", title: "خدماتي", isActive: navigator.selectedTab == 3) {
                    navigator.navigate(to: "services")
                }
                TabItem(icon: "house.fill", title: "الرئيسية", isActive: navigator.selectedTab == 4) {
                    navigator.navigate(to: "home")
                }
            }
            .padding(.horizontal, 6)
            .padding(.top, 4)
            .padding(.bottom, 10)
            .background(Color.absherCard.opacity(0.97))
        }
    }
    
    // MARK: - Process Voice Command
    
    func processVoiceCommand(_ command: String) {
        isProcessing = true
        
        Task {
            do {
                let response = try await ai.processCommand(command)
                
                await MainActor.run {
                    aiResponse = response.message
                    wakeWordManager.speak(response.message)
                    
                    if response.action == .navigate, let screen = response.screen {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                showAssistant = false
                            }
                            aiResponse = ""
                            navigator.navigate(to: screen)
                            wakeWordManager.deactivateAssistant()
                        }
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                            withAnimation {
                                showAssistant = false
                            }
                            aiResponse = ""
                            wakeWordManager.deactivateAssistant()
                        }
                    }
                    
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    aiResponse = "عذراً، حدث خطأ"
                    wakeWordManager.speak("عذراً، حدث خطأ")
                    isProcessing = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            showAssistant = false
                        }
                        aiResponse = ""
                        wakeWordManager.deactivateAssistant()
                    }
                }
            }
        }
    }
}

// MARK: - Home View
struct HomeView: View {
    @ObservedObject var navigator: AppNavigator
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .trailing, spacing: 20) {
                // Top Bar
                HStack {
                    Button(action: {}) {
                        Image(systemName: "bell")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.absherMint)
                            .padding(10)
                            .background(Color.absherCard)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.absherMint)
                            .padding(10)
                            .background(Color.absherCard)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
                .padding(.horizontal)
                
                // Title
                Text("الرئيسية")
                    .font(.absher(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal)
                
                // Profile Card
                HStack {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 5) {
                        Text("عبير بدر ابراهيم الشبرمي")
                            .font(.absher(size: 17, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("رقم الهوية:")
                            .font(.absher(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.title)
                                .foregroundColor(.gray)
                        )
                }
                .padding(20)
                .background(Color.absherCard)
                .cornerRadius(22)
                .padding(.horizontal)
                
                // Quick Services
                Text("الوصول السريع")
                    .font(.absher(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ServiceCard(icon: "square.stack.3d.up.fill", title: "خدمات الهوية") {
                        navigator.navigate(to: "identity")
                    }
                    ServiceCard(icon: "globe.europe.africa.fill", title: "جواز السفر") {
                        navigator.navigate(to: "passport")
                    }
                    ServiceCard(icon: "creditcard.fill", title: "رخصة القيادة") {
                        navigator.navigate(to: "driving")
                    }
                    ServiceCard(icon: "car.fill", title: "تسجيل حادث") {
                        navigator.navigate(to: "traffic")
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Services View (خدماتي)
struct ServicesView: View {
    @ObservedObject var navigator: AppNavigator
    
    let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .trailing, spacing: 20) {
                // Top Bar
                HStack {
                    Button(action: {}) {
                        Image(systemName: "bell")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.absherMint)
                            .padding(10)
                            .background(Color.absherCard)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.absherMint)
                            .padding(10)
                            .background(Color.absherCard)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
                .padding(.horizontal)
                
                // Title
                Text("خدماتي")
                    .font(.absher(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal)
                
                // Search Bar
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.absherCard)
                    .frame(height: 50)
                    .overlay(
                        HStack {
                            Text("ابحث باسم الخدمة")
                                .font(.absher(size: 15))
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.absherMint)
                        }
                        .padding(.horizontal, 16)
                    )
                    .padding(.horizontal)
                
                // Services Grid
                LazyVGrid(columns: columns, spacing: 14) {
                    ServiceCard(icon: "square.stack.3d.up.fill", title: "خدمات الهوية الوطنية") {
                        navigator.navigate(to: "identity")
                    }
                    ServiceCard(icon: "car.fill", title: "تسجيل حادث بسيط") {
                        navigator.navigate(to: "traffic")
                    }
                    ServiceCard(icon: "globe.europe.africa.fill", title: "تجديد جواز السفر") {
                        navigator.navigate(to: "passport")
                    }
                    ServiceCard(icon: "creditcard.fill", title: "تجديد رخصة القيادة") {
                        navigator.navigate(to: "driving")
                    }
                    ServiceCard(icon: "figure.2.and.child.holdinghands", title: "تسجيل المواليد") {
                        navigator.navigate(to: "civil")
                    }
                    ServiceCard(icon: "person.3.fill", title: "خدمات سجل الأسرة") {
                        navigator.navigate(to: "civil")
                    }
                    ServiceCard(icon: "touchid", title: "خدمات التوثق") {
                        navigator.navigate(to: "identity")
                    }
                    ServiceCard(icon: "airplane", title: "التأشيرات") {
                        navigator.navigate(to: "visa")
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Service Detail View
struct ServiceDetailView: View {
    let screen: AppScreen
    @ObservedObject var navigator: AppNavigator
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { navigator.goHome() }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.absherMint)
                }
                
                Spacer()
                
                Text(screen.arabicName)
                    .font(.absher(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: screen.icon)
                    .font(.title2)
                    .foregroundColor(.absherMint)
            }
            .padding()
            .background(Color.absherCard)
            
            // Content
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: screen.icon)
                    .font(.system(size: 80))
                    .foregroundColor(.absherMint)
                
                Text(screen.arabicName)
                    .font(.absher(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("قل \"يا أبشر\" للمساعدة")
                    .font(.absher(size: 16))
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    ContentView()
}
