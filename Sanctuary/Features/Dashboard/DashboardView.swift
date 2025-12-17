//
//  DashboardView.swift
//  Sanctuary
//
//  Main dashboard with BentoGrid layout
//

import SwiftUI

struct DashboardView: View {
    @Environment(DependencyContainer.self) private var dependencies
    @State private var showingSettings = false
    @State private var showingConsentSelection = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                backgroundView
                
                // Content
                ScrollView {
                    VStack(spacing: DesignTokens.spacingLarge) {
                        // Safety Status Card
                        SafetyStatusCard()
                        
                        // Bento Grid
                        BentoGridView(
                            showingConsentSelection: $showingConsentSelection
                        )
                        
                        // Recent Activity
                        RecentActivitySection()
                    }
                    .padding(.horizontal, DesignTokens.spacingMedium)
                    .padding(.top, DesignTokens.spacingMedium)
                    .padding(.bottom, 100)
                }
                
                // Floating Panic Button
                VStack {
                    Spacer()
                    PanicButton()
                        .padding(.bottom, DesignTokens.spacingLarge)
                }
            }
            .navigationTitle("Sanctuary")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingConsentSelection) {
                ConsentSelectionView()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if dependencies.isPanicModeActive {
            // Panic mode animated background
            TimelineView(.animation) { timeline in
                let pulse = sin(timeline.date.timeIntervalSince1970 * 2) * 0.5 + 0.5
                MeshGradient.panicMesh(pulse: pulse)
                    .ignoresSafeArea()
            }
        } else {
            Color.sanctuaryBlack
                .ignoresSafeArea()
        }
    }
}

// MARK: - Safety Status Card

struct SafetyStatusCard: View {
    @Environment(DependencyContainer.self) private var dependencies
    
    var body: some View {
        VStack(spacing: DesignTokens.spacingMedium) {
            HStack {
                // Status icon
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: statusIcon)
                        .font(.system(size: 28))
                        .foregroundStyle(statusColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(statusTitle)
                        .font(.headlineLarge)
                        .foregroundStyle(.white)
                    
                    Text(statusSubtitle)
                        .font(.bodySmall)
                        .foregroundStyle(.textSecondary)
                }
                
                Spacer()
                
                if dependencies.isPanicModeActive {
                    // Stop button
                    Button {
                        Task {
                            await dependencies.deactivatePanicMode()
                        }
                    } label: {
                        Text("Stop")
                            .font(.labelLarge)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.statusDanger)
                            .clipShape(Capsule())
                    }
                }
            }
            
            // Location authorization warning
            if !dependencies.safetyLocationManager.authorizationStatus.canMonitorInBackground {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.statusWarning)
                    
                    Text(dependencies.safetyLocationManager.authorizationStatus.displayMessage)
                        .font(.bodySmall)
                        .foregroundStyle(.textSecondary)
                    
                    Spacer()
                    
                    Button("Fix") {
                        dependencies.safetyLocationManager.requestAlwaysAuthorization()
                    }
                    .font(.labelMedium)
                    .foregroundStyle(.safetyOrange)
                }
                .padding(DesignTokens.spacingSmall)
                .background(Color.statusWarning.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusSmall))
            }
        }
        .padding(DesignTokens.spacingMedium)
        .sanctuaryCard(isHighlighted: dependencies.isPanicModeActive)
    }
    
    private var statusColor: Color {
        dependencies.isPanicModeActive ? .statusDanger : .statusSafe
    }
    
    private var statusIcon: String {
        dependencies.isPanicModeActive ? "exclamationmark.triangle.fill" : "shield.checkered"
    }
    
    private var statusTitle: String {
        dependencies.isPanicModeActive ? "Panic Active" : "You're Safe"
    }
    
    private var statusSubtitle: String {
        if dependencies.isPanicModeActive {
            return "Sharing location with trusted contacts"
        } else {
            return "Tap the button below if you need help"
        }
    }
}

// MARK: - Bento Grid

struct BentoGridView: View {
    @Binding var showingConsentSelection: Bool
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: DesignTokens.spacingMedium) {
            // Consent Agreements
            BentoCard(
                icon: "heart.text.square.fill",
                title: "Agreements",
                subtitle: "2 active",
                color: .pink
            ) {
                showingConsentSelection = true
            }
            
            // Trusted Contacts
            BentoCard(
                icon: "person.2.fill",
                title: "Contacts",
                subtitle: "3 trusted",
                color: .blue
            ) {
                // Navigate to contacts
            }
            
            // Check-In Timer
            BentoCard(
                icon: "timer",
                title: "Check-In",
                subtitle: "Every 30 min",
                color: .green
            ) {
                // Configure timer
            }
            
            // Location Sharing
            BentoCard(
                icon: "location.fill",
                title: "Location",
                subtitle: "Always on",
                color: .safetyOrange
            ) {
                // Location settings
            }
        }
    }
}

struct BentoCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingSmall) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(color)
                
                Spacer()
                
                Text(title)
                    .font(.headlineSmall)
                    .foregroundStyle(.white)
                
                Text(subtitle)
                    .font(.labelSmall)
                    .foregroundStyle(.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DesignTokens.spacingMedium)
            .frame(height: 120)
            .sanctuaryCard()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recent Activity

struct RecentActivitySection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingMedium) {
            Text("Recent Activity")
                .font(.headlineMedium)
                .foregroundStyle(.white)
            
            VStack(spacing: DesignTokens.spacingSmall) {
                ActivityRow(
                    icon: "checkmark.circle.fill",
                    title: "Check-in confirmed",
                    time: "2 hours ago",
                    color: .statusSafe
                )
                
                ActivityRow(
                    icon: "heart.fill",
                    title: "Agreement accepted",
                    time: "Yesterday",
                    color: .pink
                )
                
                ActivityRow(
                    icon: "person.badge.plus",
                    title: "Contact added",
                    time: "2 days ago",
                    color: .blue
                )
            }
        }
    }
}

struct ActivityRow: View {
    let icon: String
    let title: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignTokens.spacingMedium) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.bodyMedium)
                    .foregroundStyle(.white)
                
                Text(time)
                    .font(.labelSmall)
                    .foregroundStyle(.textTertiary)
            }
            
            Spacer()
        }
        .padding(DesignTokens.spacingSmall)
    }
}

// MARK: - Panic Button

struct PanicButton: View {
    @Environment(DependencyContainer.self) private var dependencies
    @State private var isPressed = false
    @State private var holdProgress: CGFloat = 0
    
    private let holdDuration: CGFloat = 1.5 // seconds to hold
    
    var body: some View {
        ZStack {
            // Outer ring (progress indicator)
            Circle()
                .trim(from: 0, to: holdProgress)
                .stroke(Color.safetyOrange, lineWidth: 4)
                .rotationEffect(.degrees(-90))
                .frame(width: 88, height: 88)
            
            // Button
            Circle()
                .fill(dependencies.isPanicModeActive ? Color.statusDanger : Color.safetyOrange)
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: dependencies.isPanicModeActive ? "hand.raised.fill" : "sos")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .glowShadow(color: dependencies.isPanicModeActive ? .statusDanger : .safetyOrange)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        dependencies.hapticManager.heavyImpact()
                        startHoldTimer()
                    }
                }
                .onEnded { _ in
                    isPressed = false
                    holdProgress = 0
                }
        )
    }
    
    private func startHoldTimer() {
        Task {
            let steps = 30
            let stepDuration = holdDuration / CGFloat(steps)
            
            for i in 1...steps {
                guard isPressed else { return }
                try? await Task.sleep(for: .seconds(stepDuration))
                
                await MainActor.run {
                    holdProgress = CGFloat(i) / CGFloat(steps)
                }
                
                if i == steps {
                    // Trigger panic
                    await triggerPanic()
                }
            }
        }
    }
    
    private func triggerPanic() async {
        dependencies.hapticManager.panicConfirmation()
        
        do {
            try await dependencies.activatePanicMode()
        } catch {
            print("Failed to activate panic mode: \(error)")
        }
        
        isPressed = false
        holdProgress = 0
    }
}

#Preview {
    DashboardView()
        .environment(DependencyContainer.shared)
}
