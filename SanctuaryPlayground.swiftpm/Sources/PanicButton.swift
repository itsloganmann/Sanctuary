//
//  PanicButton.swift
//  Sanctuary
//
//  Hold-to-activate panic button with progress ring and haptic feedback
//

import SwiftUI

struct PanicButton: View {
    @Environment(AppState.self) private var appState
    @State private var isPressed = false
    @State private var holdProgress: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    
    private let holdDuration: CGFloat = 1.5
    
    var body: some View {
        ZStack {
            // Pulse ring (panic active)
            if appState.isPanicModeActive {
                Circle()
                    .stroke(Color.statusDanger.opacity(0.3), lineWidth: 2)
                    .frame(width: 100, height: 100)
                    .scaleEffect(pulseScale)
                    .opacity(2 - Double(pulseScale))
                    .onAppear {
                        withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                            pulseScale = 2.0
                        }
                    }
            }
            
            // Progress ring
            Circle()
                .trim(from: 0, to: holdProgress)
                .stroke(Color.safetyOrange, lineWidth: 4)
                .rotationEffect(.degrees(-90))
                .frame(width: 88, height: 88)
            
            // Button body
            Circle()
                .fill(appState.isPanicModeActive ? Color.statusDanger : Color.safetyOrange)
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: appState.isPanicModeActive ? "hand.raised.fill" : "sos")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                )
                .scaleEffect(isPressed ? 0.92 : 1.0)
                .glowShadow(color: appState.isPanicModeActive ? .statusDanger : .safetyOrange)
                .animation(.easeOut(duration: 0.15), value: isPressed)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        startHoldTimer()
                    }
                }
                .onEnded { _ in
                    isPressed = false
                    holdProgress = 0
                }
        )
        .accessibilityLabel(appState.isPanicModeActive ? "Panic mode active" : "Hold to activate panic mode")
        .accessibilityHint("Press and hold for 1.5 seconds to trigger emergency alert")
    }
    
    private func startHoldTimer() {
        Task {
            let steps = 30
            let stepDuration = holdDuration / CGFloat(steps)
            
            for i in 1...steps {
                guard isPressed else { return }
                try? await Task.sleep(for: .seconds(stepDuration))
                
                await MainActor.run {
                    withAnimation(.linear(duration: stepDuration)) {
                        holdProgress = CGFloat(i) / CGFloat(steps)
                    }
                }
                
                if i == steps {
                    await MainActor.run {
                        withAnimation(.spring(response: 0.4)) {
                            appState.activatePanicMode()
                        }
                    }
                    isPressed = false
                    holdProgress = 0
                }
            }
        }
    }
}
