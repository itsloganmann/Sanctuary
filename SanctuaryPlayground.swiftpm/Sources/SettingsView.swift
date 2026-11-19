//
//  SettingsView.swift
//  Sanctuary
//
//  App settings: emergency message, check-in interval, stealth mode
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    
    var body: some View {
        @Bindable var state = appState
        
        NavigationStack {
            List {
                // Profile
                Section("Profile") {
                    if let user = appState.currentUser {
                        HStack(spacing: DesignTokens.spacingMedium) {
                            Circle()
                                .fill(Color.safetyOrange.opacity(0.2))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text(user.displayName.prefix(1).uppercased())
                                        .font(.headlineLarge)
                                        .foregroundStyle(Color.safetyOrange)
                                )
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.displayName)
                                    .font(.headlineMedium)
                                Text(user.phone)
                                    .font(.bodySmall)
                                    .foregroundStyle(Color.textSecondary)
                            }
                        }
                        .padding(.vertical, DesignTokens.spacingSmall)
                    }
                }
                
                // Safety Settings
                Section("Safety Settings") {
                    VStack(alignment: .leading, spacing: DesignTokens.spacingSmall) {
                        Text("Emergency Message")
                            .font(.labelMedium)
                            .foregroundStyle(Color.textSecondary)
                        TextField("Message sent to contacts", text: $state.emergencyMessage)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.vertical, DesignTokens.spacingSmall)
                    
                    VStack(alignment: .leading, spacing: DesignTokens.spacingSmall) {
                        HStack {
                            Text("Check-In Interval")
                            Spacer()
                            Text("\(appState.checkInIntervalMinutes) min")
                                .foregroundStyle(Color.safetyOrange)
                        }
                        Slider(
                            value: Binding(
                                get: { Double(appState.checkInIntervalMinutes) },
                                set: { appState.checkInIntervalMinutes = Int($0) }
                            ),
                            in: 5...120, step: 5
                        )
                        .tint(Color.safetyOrange)
                    }
                    .padding(.vertical, DesignTokens.spacingSmall)
                    
                    Toggle(isOn: $state.isStealthModeEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Stealth Mode")
                            Text("Dims screen while monitoring")
                                .font(.labelSmall)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                    .tint(Color.safetyOrange)
                }
                
                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0 (Playground)")
                            .foregroundStyle(Color.textSecondary)
                    }
                    HStack {
                        Text("Built with")
                        Spacer()
                        Text("SwiftUI · iOS 18")
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                
                // Sign Out
                Section {
                    Button(role: .destructive) {
                        withAnimation { appState.signOut() }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.safetyOrange)
                }
            }
        }
    }
}
