//
//  DashboardView.swift
//  Sanctuary
//
//  Main BentoGrid dashboard with safety status, panic button, and quick actions
//

import SwiftUI

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    
    enum ActiveSheet: Identifiable {
        case settings, consent, contacts, agreements
        var id: Int { hashValue }
    }
    @State private var activeSheet: ActiveSheet?
    @State private var showCheckInToast = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundView
                
                ScrollView {
                    VStack(spacing: DesignTokens.spacingLarge) {
                        SafetyStatusCard()
                        bentoGrid
                        RecentActivitySection()
                    }
                    .padding(.horizontal, DesignTokens.spacingMedium)
                    .padding(.top, DesignTokens.spacingMedium)
                    .padding(.bottom, 120)
                }
                
                // Floating Panic Button
                VStack {
                    Spacer()
                    PanicButton()
                        .padding(.bottom, DesignTokens.spacingLarge)
                }
                
                // Check-in toast
                if showCheckInToast {
                    VStack {
                        Spacer()
                        toastView
                            .padding(.bottom, 120)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle("Sanctuary")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { activeSheet = .settings } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
            .sheet(item: $activeSheet) { item in
                switch item {
                case .settings:   SettingsView()
                case .consent:    ConsentSelectionView()
                case .contacts:   TrustedContactsListView()
                case .agreements: AgreementListView()
                }
            }
            .preferredColorScheme(.dark)
        }
    }
    
    // MARK: - Background
    
    @ViewBuilder
    private var backgroundView: some View {
        if appState.isPanicModeActive {
            TimelineView(.animation) { timeline in
                let pulse = sin(timeline.date.timeIntervalSince1970 * 2) * 0.5 + 0.5
                MeshGradient.panicMesh(pulse: pulse)
                    .ignoresSafeArea()
            }
        } else {
            Color.sanctuaryBlack.ignoresSafeArea()
        }
    }
    
    // MARK: - Bento Grid
    
    private var bentoGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: DesignTokens.spacingMedium) {
            BentoCard(icon: "heart.text.square.fill", title: "Boundaries", subtitle: "\(appState.agreements.count) agreements", color: .pink) {
                activeSheet = .consent
            }
            BentoCard(icon: "person.2.fill", title: "Contacts", subtitle: "\(appState.trustedContacts.count) trusted", color: .blue) {
                activeSheet = .contacts
            }
            BentoCard(icon: "timer", title: "Check-In", subtitle: "Every \(appState.checkInIntervalMinutes) min", color: .statusSafe) {
                performCheckIn()
            }
            BentoCard(icon: "doc.text.fill", title: "Agreements", subtitle: "Review all", color: .purple) {
                activeSheet = .agreements
            }
        }
    }
    
    // MARK: - Toast
    
    private var toastView: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.statusSafe)
            Text("Check-in sent!")
                .font(.headlineSmall)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
    
    private func performCheckIn() {
        appState.checkIn()
        withAnimation(.spring(response: 0.3)) { showCheckInToast = true }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { showCheckInToast = false }
        }
    }
}

// MARK: - Safety Status Card

struct SafetyStatusCard: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(spacing: DesignTokens.spacingMedium) {
            HStack {
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
                        .foregroundStyle(Color.textSecondary)
                }
                
                Spacer()
                
                if appState.isPanicModeActive {
                    Button {
                        withAnimation(.spring(response: 0.4)) {
                            appState.deactivatePanicMode()
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
            
            if appState.isPanicModeActive {
                // Simulated location sharing info
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .foregroundStyle(Color.statusDanger)
                        .font(.caption)
                    Text("Broadcasting GPS to \(appState.trustedContacts.count) contacts")
                        .font(.labelSmall)
                        .foregroundStyle(Color.textSecondary)
                    Spacer()
                    if let start = appState.monitoringStartTime {
                        Text(start, style: .relative)
                            .font(.labelSmall)
                            .foregroundStyle(Color.statusDanger)
                    }
                }
                .padding(DesignTokens.spacingSmall)
                .background(Color.statusDanger.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusSmall))
            }
        }
        .padding(DesignTokens.spacingMedium)
        .sanctuaryCard(isHighlighted: appState.isPanicModeActive)
    }
    
    private var statusColor: Color {
        appState.isPanicModeActive ? .statusDanger : .statusSafe
    }
    private var statusIcon: String {
        appState.isPanicModeActive ? "exclamationmark.triangle.fill" : "shield.checkered"
    }
    private var statusTitle: String {
        appState.isPanicModeActive ? "Panic Active" : "You're Safe"
    }
    private var statusSubtitle: String {
        appState.isPanicModeActive
            ? "Sharing location with trusted contacts"
            : "Hold the button below if you need help"
    }
}

// MARK: - Bento Card

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
                    .foregroundStyle(Color.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DesignTokens.spacingMedium)
            .frame(height: 120)
            .sanctuaryCard()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title): \(subtitle)")
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
                ActivityRow(icon: "checkmark.circle.fill", title: "Check-in confirmed",  time: "2 hours ago", color: .statusSafe)
                ActivityRow(icon: "heart.fill",            title: "Agreement accepted",   time: "Yesterday",    color: .pink)
                ActivityRow(icon: "person.badge.plus",     title: "Contact added",        time: "2 days ago",   color: .blue)
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
                    .foregroundStyle(Color.textTertiary)
            }
            Spacer()
        }
        .padding(DesignTokens.spacingSmall)
        .accessibilityElement(children: .combine)
    }
}
