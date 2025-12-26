//
//  SafetyIntents.swift
//  Sanctuary
//
//  App Intents for Widget and Live Activity interactions
//
//  LIFECYCLE ANALYSIS: AppIntent -> LiveActivity -> Background Location
//  =====================================================================
//
//  The challenge: iOS suspends apps aggressively. We need location updates
//  even when the app is in the background or the screen is locked.
//
//  Solution Chain:
//  1. User taps widget button -> ToggleSafetyMonitoringIntent runs
//  2. Intent has `openAppWhenRun = true` -> App gets foreground time
//  3. While in foreground, we:
//     a. Start CLBackgroundActivitySession (MUST be in foreground)
//     b. Enable allowsBackgroundLocationUpdates
//     c. Start Live Activity (keeps UI on lock screen)
//     d. Begin CLLocationUpdate.liveUpdates() async stream
//  4. App goes to background but:
//     - CLBackgroundActivitySession keeps it from suspending
//     - Location updates continue via the async stream
//     - Live Activity provides user visibility and quick actions
//  5. User can interact via Live Activity buttons without unlocking
//
//  Trade-off: `openAppWhenRun = true` briefly shows the app, but this is
//  necessary to establish the background session. The app can immediately
//  return to background once the session is established.
//

import AppIntents
import ActivityKit
import WidgetKit

// MARK: - Toggle Safety Monitoring Intent

/// Intent to start or stop safety monitoring from widget
///
/// This is the primary entry point for activating panic mode from the lock screen.
/// Setting `openAppWhenRun = true` ensures we get enough foreground time to
/// establish the background location session.
struct ToggleSafetyMonitoringIntent: LiveActivityIntent {
    
    static let title: LocalizedStringResource = "Toggle Safety Monitoring"
    static let description: IntentDescription = "Start or stop safety monitoring"
    
    // CRITICAL: This ensures the app gets foreground time to start background location
    static var openAppWhenRun: Bool { true }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let dependencies = DependencyContainer.shared
        
        if dependencies.isPanicModeActive {
            // Stop monitoring
            await dependencies.deactivatePanicMode()
            await stopLiveActivity()
        } else {
            // Start monitoring (panic mode)
            try await dependencies.activatePanicMode()
            // This will trigger SafetyLocationManager.startPanicMode(), which sends alert
            await startLiveActivity()
        }
        
        return .result()
    }
    
    @MainActor
    private func startLiveActivity() async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = SafetyActivityAttributes(
            userName: DependencyContainer.shared.authManager.currentUser?.profile?.displayName ?? "User",
            alertId: nil
        )
        
        let initialState = SafetyActivityAttributes.ContentState(
            status: .monitoring,
            startedAt: Date(),
            lastLocationDescription: nil,
            batteryLevel: DependencyContainer.shared.safetyLocationManager.getBatteryLevel(),
            contactsNotified: 0,
            customMessage: nil,
            escalationTime: nil
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: .token
            )
            
            // Store activity ID for later updates
            UserDefaults.standard.set(activity.id, forKey: "currentSafetyActivityId")
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    @MainActor
    private func stopLiveActivity() async {
        guard let activityId = UserDefaults.standard.string(forKey: "currentSafetyActivityId") else { return }
        
        for activity in Activity<SafetyActivityAttributes>.activities {
            if activity.id == activityId {
                let finalState = SafetyActivityAttributes.ContentState(
                    status: .resolved,
                    startedAt: activity.content.state.startedAt,
                    lastLocationDescription: nil,
                    batteryLevel: nil,
                    contactsNotified: 0,
                    customMessage: nil,
                    escalationTime: nil
                )
                
                await activity.end(
                    .init(state: finalState, staleDate: nil),
                    dismissalPolicy: .after(.now + 60)
                )
            }
        }
        
        UserDefaults.standard.removeObject(forKey: "currentSafetyActivityId")
    }
}

// MARK: - Panic Button Intent

/// Intent for the panic button - escalates to full emergency mode
struct PanicButtonIntent: LiveActivityIntent {
    
    static let title: LocalizedStringResource = "Panic Alert"
    static let description: IntentDescription = "Trigger emergency panic alert"
    
    static var openAppWhenRun: Bool { true }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let dependencies = DependencyContainer.shared
        
        // Heavy haptic feedback
        dependencies.hapticManager.panicConfirmation()
        
        // Activate panic mode if not already active
        if !dependencies.isPanicModeActive {
            try await dependencies.activatePanicMode()
            // This will trigger SafetyLocationManager.startPanicMode(), which sends alert
        }
        
        // Update Live Activity to panic state
        await updateLiveActivityToPanic()
        
        // Create safety alert in database
        if let userId = dependencies.authManager.currentUser?.id {
            let alert = SafetyAlert.newPanic(
                userId: userId,
                location: dependencies.safetyLocationManager.currentLocation,
                batteryLevel: dependencies.safetyLocationManager.getBatteryLevel()
            )
            
            _ = try? await dependencies.safetyAlertRepository.create(alert)
        }
        
        return .result()
    }
    
    @MainActor
    private func updateLiveActivityToPanic() async {
        for activity in Activity<SafetyActivityAttributes>.activities {
            let panicState = SafetyActivityAttributes.ContentState(
                status: .panic,
                startedAt: activity.content.state.startedAt,
                lastLocationDescription: activity.content.state.lastLocationDescription,
                batteryLevel: activity.content.state.batteryLevel,
                contactsNotified: activity.content.state.contactsNotified,
                customMessage: "EMERGENCY - Help needed!",
                escalationTime: Date().addingTimeInterval(300) // 5 min to auto-escalate
            )
            
            await activity.update(.init(state: panicState, staleDate: nil))
        }
    }
}

// MARK: - Check In Intent

/// Intent for check-in button - confirms user is safe
struct CheckInIntent: LiveActivityIntent {
    
    static let title: LocalizedStringResource = "Check In"
    static let description: IntentDescription = "Confirm you are safe"
    
    // Check-in can run without opening app fully
    static var openAppWhenRun: Bool { false }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let dependencies = DependencyContainer.shared
        
        // Gentle confirmation haptic
        dependencies.hapticManager.checkInConfirmation()
        
        // Reset the Dead Man's Switch timer
        await resetEscalationTimer()
        
        // Update last check-in time
        UserDefaults.standard.set(Date(), forKey: "lastCheckInTime")
        
        return .result()
    }
    
    @MainActor
    private func resetEscalationTimer() async {
        for activity in Activity<SafetyActivityAttributes>.activities {
            let updatedState = SafetyActivityAttributes.ContentState(
                status: .monitoring,
                startedAt: activity.content.state.startedAt,
                lastLocationDescription: activity.content.state.lastLocationDescription,
                batteryLevel: DependencyContainer.shared.safetyLocationManager.getBatteryLevel(),
                contactsNotified: activity.content.state.contactsNotified,
                customMessage: "Checked in at \(Date().formatted(date: .omitted, time: .shortened))",
                escalationTime: nil
            )
            
            await activity.update(.init(state: updatedState, staleDate: nil))
        }
    }
}

// MARK: - Stop Monitoring Intent

/// Intent to stop all monitoring and resolve alerts
struct StopMonitoringIntent: LiveActivityIntent {
    
    static let title: LocalizedStringResource = "Stop Monitoring"
    static let description: IntentDescription = "Stop safety monitoring and resolve any alerts"
    
    static var openAppWhenRun: Bool { true }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let dependencies = DependencyContainer.shared
        
        await dependencies.deactivatePanicMode()
        
        // End all Live Activities
        for activity in Activity<SafetyActivityAttributes>.activities {
            let finalState = SafetyActivityAttributes.ContentState(
                status: .resolved,
                startedAt: activity.content.state.startedAt,
                lastLocationDescription: nil,
                batteryLevel: nil,
                contactsNotified: 0,
                customMessage: "Monitoring stopped",
                escalationTime: nil
            )
            
            await activity.end(
                .init(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }
        
        dependencies.hapticManager.success()
        
        return .result()
    }
}

// MARK: - App Shortcuts Provider

struct SanctuaryShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ToggleSafetyMonitoringIntent(),
            phrases: [
                "Start \(.applicationName) monitoring",
                "I need help with \(.applicationName)",
                "\(.applicationName) panic mode"
            ],
            shortTitle: "Safety Monitoring",
            systemImageName: "shield.fill"
        )
    }
}
