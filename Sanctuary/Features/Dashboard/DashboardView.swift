// MARK: - Add Trusted Contact View (inline for scope)
import SwiftUI

struct AddTrustedContactView: View {
    @Environment(DependencyContainer.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var phoneNumber = ""
    @State private var displayName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    var onAdd: (TrustedContact) -> Void
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Contact Info")) {
                    TextField("Name", text: $displayName)
                        .disabled(isLoading)
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .disabled(isLoading)
                }
                if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
            .overlay(
                Group {
                    if isLoading {
                        ZStack {
                            Color.black.opacity(0.2).ignoresSafeArea()
                            ProgressView("Adding contact...")
                        }
                    }
                }
            )
            .navigationTitle("Add Contact")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addContact()
                    }
                    .disabled(displayName.isEmpty || phoneNumber.isEmpty || isLoading)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isLoading)
                }
            }
        }
    }
    func addContact() {
        isLoading = true
        errorMessage = nil
        Task {
            guard let userId = dependencies.authManager.currentUser?.id else {
                errorMessage = "Not authenticated. Please log in."
                isLoading = false
                return
            }
            do {
                let newProfile = try await dependencies.profileRepository.addTrustedContact(for: userId, displayName: displayName, phoneNumber: phoneNumber)
                // Convert Profile to ProfileJoined for the TrustedContact model
                let joinedProfile = ProfileJoined(
                    id: newProfile.id,
                    phoneNumber: newProfile.phoneNumber,
                    displayName: newProfile.displayName,
                    avatarUrl: newProfile.avatarUrl,
                    emergencyMessage: newProfile.emergencyMessage,
                    isMonitoringEnabled: newProfile.isMonitoringEnabled,
                    checkInIntervalMinutes: newProfile.checkInIntervalMinutes,
                    createdAt: newProfile.createdAt,
                    updatedAt: newProfile.updatedAt
                )
                let trustedContact = TrustedContact(
                    trustedContactId: newProfile.id,
                    relationType: .emergency, // or your default
                    profiles: joinedProfile
                )
                onAdd(trustedContact)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

import SwiftUI

struct TrustedContactsView: View {
    @Environment(DependencyContainer.self) private var dependencies
    @State private var contacts: [TrustedContact] = []
    @State private var isLoading = false
    @State private var showAddContact = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView("Loading contacts...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if contacts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No trusted contacts yet.")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text("Add a trusted contact to receive alerts in an emergency.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(contacts) { contact in
                            VStack(alignment: .leading) {
                                Text(contact.displayName)
                                    .font(.headline)
                                Text(contact.phoneNumber ?? "")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete(perform: deleteContact)
                    }
                }
            }
            .navigationTitle("Trusted Contacts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddContact = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(isLoading)
                }
            }
            .sheet(isPresented: $showAddContact) {
                AddTrustedContactView(onAdd: { newContact in
                    contacts.append(newContact)
                    loadContacts()
                })
            }
            .onAppear(perform: loadContacts)
            .alert(isPresented: .constant(errorMessage != nil), content: {
                Alert(title: Text("Error"), message: Text(errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK"), action: { errorMessage = nil }))
            })
        }
    }
    
    func loadContacts() {
        isLoading = true
        Task {
            guard let userId = dependencies.authManager.currentUser?.id else {
                errorMessage = "Not authenticated. Please log in."
                isLoading = false
                return
            }
            do {
                contacts = try await dependencies.profileRepository.getTrustedContacts(for: userId)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    func deleteContact(at offsets: IndexSet) {
        let toDelete = offsets.map { contacts[$0] }
        Task {
            for contact in toDelete {
                do {
                    guard let userId = dependencies.authManager.currentUser?.id else {
                        errorMessage = "Not authenticated. Please log in."
                        return
                    }
                    try await dependencies.profileRepository.removeTrustedContact(for: userId, contactId: contact.id)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
            loadContacts()
        }
    }
}

struct LocationSettingsView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "location.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.safetyOrange)
            Text("Location sharing is always enabled for safety monitoring.")
                .font(.title3)
                .multilineTextAlignment(.center)
            Text("You can manage location permissions in iOS Settings > Sanctuary.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
//
//  DashboardView.swift
//  Sanctuary
//
//  Main dashboard with BentoGrid layout
//

import SwiftUI

struct DashboardView: View {
    @Environment(DependencyContainer.self) private var dependencies
    enum ActiveSheet: Identifiable {
        case settings, consent, contacts, location
        var id: Int { hashValue }
    }
    @State private var activeSheet: ActiveSheet?
    @State private var isCheckInSending = false
    @State private var checkInError: String?
    
    var body: some View {
        NavigationStack {
            Text("DEBUG: DashboardView loaded")
                .foregroundColor(.green)
            ZStack {
                // Background
                backgroundView
                // Content
                ScrollView {
                    VStack(spacing: DesignTokens.spacingLarge) {
                        SafetyStatusCard()
                        BentoGridView(
                            activeSheet: $activeSheet,
                            onCheckIn: handleCheckIn
                        )
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
                        activeSheet = .settings
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
            .sheet(item: $activeSheet) { item in
                switch item {
                case .settings: SettingsView()
                case .consent: ConsentSelectionView()
                case .contacts: TrustedContactsView()
                case .location: LocationSettingsView()
                }
            }
            .alert(isPresented: .constant(checkInError != nil), content: {
                Alert(title: Text("Check-In Failed"), message: Text(checkInError ?? "Unknown error"), dismissButton: .default(Text("OK"), action: { checkInError = nil }))
            })
            .preferredColorScheme(.dark)
        }
    }

    // Check-In action: send check-in SMS to trusted contacts
    func handleCheckIn() {
        isCheckInSending = true
        Task {
            let location = dependencies.safetyLocationManager.currentLocation
            let message = "Check-in: I am safe."
            await dependencies.safetyLocationManager.sendAlertToContacts(location: location ?? .init(latitude: 0, longitude: 0), message: message)
            isCheckInSending = false
        }
    }

    @ViewBuilder
    var backgroundView: some View {
        if dependencies.isPanicModeActive {
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
                        .foregroundStyle(Color.textSecondary)
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
                        .foregroundStyle(Color.statusWarning)
                    
                    Text(dependencies.safetyLocationManager.authorizationStatus.displayMessage)
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                    
                    Spacer()
                    
                    Button("Fix") {
                        dependencies.safetyLocationManager.requestAlwaysAuthorization()
                    }
                    .font(.labelMedium)
                    .foregroundStyle(Color.safetyOrange)
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
    @Binding var activeSheet: DashboardView.ActiveSheet?
    var onCheckIn: () -> Void

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
                activeSheet = .consent
            }
            // Trusted Contacts
            BentoCard(
                icon: "person.2.fill",
                title: "Contacts",
                subtitle: "3 trusted",
                color: .blue
            ) {
                print("Contacts card tapped!")
                activeSheet = .contacts
            }
            // Check-In Timer
            BentoCard(
                icon: "timer",
                title: "Check-In",
                subtitle: "Every 30 min",
                color: .green
            ) {
                onCheckIn()
            }
            // Location Sharing
            BentoCard(
                icon: "location.fill",
                title: "Location",
                subtitle: "Always on",
                color: .safetyOrange
            ) {
                activeSheet = .location
            }
        }
    }
// Placeholder for location settings/screen
struct LocationSettingsView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "location.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.safetyOrange)
            Text("Location sharing is always enabled for safety monitoring.")
                .font(.title3)
                .multilineTextAlignment(.center)
            Text("You can manage location permissions in iOS Settings > Sanctuary.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
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
                    .foregroundStyle(Color.textSecondary)
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
                    .foregroundStyle(Color.textTertiary)
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
                .glowShadow(color: dependencies.isPanicModeActive ? Color.statusDanger : Color.safetyOrange)
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
