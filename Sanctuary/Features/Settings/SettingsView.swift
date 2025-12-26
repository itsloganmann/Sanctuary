//
//  SettingsView.swift
//  Sanctuary
//
//  App settings and profile management
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DependencyContainer.self) private var dependencies
    
    @State private var emergencyMessage = ""
    @State private var checkInInterval = 30
    @State private var isStealthModeEnabled = false
    @State private var showingSignOutConfirmation = false
    
    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section {
                    if let profile = dependencies.authManager.currentUser?.profile {
                        HStack(spacing: DesignTokens.spacingMedium) {
                            // Avatar
                            Circle()
                                .fill(Color.safetyOrange.opacity(0.2))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text(profile.displayName.prefix(1).uppercased())
                                        .font(.headlineLarge)
                                        .foregroundStyle(Color.safetyOrange)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(profile.displayName)
                                    .font(.headlineMedium)
                                
                                if let phone = profile.phoneNumber {
                                    Text(phone)
                                        .font(.bodySmall)
                                        .foregroundStyle(Color.textSecondary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Color.textTertiary)
                        }
                        .padding(.vertical, DesignTokens.spacingSmall)
                    }
                } header: {
                    Text("Profile")
                }
                
                // Safety Settings
                Section {
                    // Emergency message
                    VStack(alignment: .leading, spacing: DesignTokens.spacingSmall) {
                        Text("Emergency Message")
                            .font(.labelMedium)
                            .foregroundStyle(Color.textSecondary)
                        
                        TextField("Message sent to contacts", text: $emergencyMessage)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.vertical, DesignTokens.spacingSmall)
                    
                    // Check-in interval
                    VStack(alignment: .leading, spacing: DesignTokens.spacingSmall) {
                        HStack {
                            Text("Check-In Interval")
                            Spacer()
                            Text("\(checkInInterval) min")
                                .foregroundStyle(Color.safetyOrange)
                        }
                        
                        Slider(value: Binding(
                            get: { Double(checkInInterval) },
                            set: { checkInInterval = Int($0) }
                        ), in: 5...120, step: 5)
                        .tint(Color.safetyOrange)
                    }
                    .padding(.vertical, DesignTokens.spacingSmall)
                    
                    // Stealth mode
                    Toggle(isOn: $isStealthModeEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Stealth Mode")
                            Text("Dims screen while monitoring")
                                .font(.labelSmall)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                    .tint(Color.safetyOrange)
                } header: {
                    Text("Safety Settings")
                }
                
                // Permissions
                Section {
                    // Location
                    PermissionRow(
                        icon: "location.fill",
                        title: "Location",
                        status: dependencies.safetyLocationManager.authorizationStatus.displayMessage,
                        isGranted: dependencies.safetyLocationManager.authorizationStatus.canMonitorInBackground
                    ) {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    
                    // Notifications
                    PermissionRow(
                        icon: "bell.fill",
                        title: "Notifications",
                        status: "Enabled",
                        isGranted: true
                    ) {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                } header: {
                    Text("Permissions")
                }
                
                // About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(Color.textSecondary)
                    }
                    
                    Link(destination: URL(string: "https://sanctuary.app/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundStyle(Color.textTertiary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://sanctuary.app/terms")!) {
                        HStack {
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundStyle(Color.textTertiary)
                        }
                    }
                } header: {
                    Text("About")
                }
                
                // Sign Out
                Section {
                    Button(role: .destructive) {
                        showingSignOutConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                            Spacer()
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.sanctuaryBlack)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color.safetyOrange)
                }
            }
            .confirmationDialog("Sign Out", isPresented: $showingSignOutConfirmation) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        await dependencies.authManager.signOut()
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .onAppear {
                loadSettings()
            }
        }
    }
    
    private func loadSettings() {
        if let profile = dependencies.authManager.currentUser?.profile {
            emergencyMessage = profile.emergencyMessage
            checkInInterval = profile.checkInIntervalMinutes
        }
        isStealthModeEnabled = dependencies.isStealthModeEnabled
    }
}

// MARK: - Permission Row

struct PermissionRow: View {
    let icon: String
    let title: String
    let status: String
    let isGranted: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.spacingMedium) {
                Image(systemName: icon)
                    .foregroundStyle(isGranted ? Color.statusSafe : Color.statusWarning)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                    Text(status)
                        .font(.labelSmall)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if !isGranted {
                    Text("Fix")
                        .font(.labelMedium)
                        .foregroundStyle(Color.safetyOrange)
                }
            }
        }
        .foregroundStyle(.white)
    }
}

#Preview {
    SettingsView()
        .environment(DependencyContainer.shared)
}
