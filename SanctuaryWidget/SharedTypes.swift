//
//  SharedTypes.swift
//  SanctuaryWidget
//
//  Shared types between main app and widget targets.
//  This file duplicates types from the main app that the widget needs.
//
//  NOTE: Keep in sync with:
//    - Sanctuary/Core/Models/SafetyActivityAttributes.swift
//    - Sanctuary/Core/Intents/SafetyIntents.swift
//

import ActivityKit
import AppIntents
import Foundation
import SwiftUI

// MARK: - Safety Activity Attributes

/// Attributes for Safety Monitoring Live Activity
struct SafetyActivityAttributes: ActivityAttributes {
    
    /// Dynamic content state that can update during the activity
    public struct ContentState: Codable, Hashable {
        /// Current monitoring status
        var status: MonitoringStatus
        
        /// Time monitoring started
        var startedAt: Date
        
        /// Last known location (for display)
        var lastLocationDescription: String?
        
        /// Battery level when started
        var batteryLevel: Double?
        
        /// Number of trusted contacts being notified
        var contactsNotified: Int
        
        /// Custom message if any
        var customMessage: String?
        
        /// Time until auto-escalation (for Dead Man's Switch)
        var escalationTime: Date?
    }
    
    /// User's display name (static for the activity duration)
    var userName: String
    
    /// Alert ID if this is an active panic alert
    var alertId: UUID?
}

// MARK: - Monitoring Status

/// Monitoring status for Live Activity display
enum MonitoringStatus: String, Codable {
    case idle
    case monitoring
    case panic
    case resolved
    
    var displayText: String {
        switch self {
        case .idle: return "Ready"
        case .monitoring: return "Monitoring Active"
        case .panic: return "PANIC ALERT"
        case .resolved: return "Resolved"
        }
    }
    
    var icon: String {
        switch self {
        case .idle: return "shield.checkered"
        case .monitoring: return "dot.radiowaves.left.and.right"
        case .panic: return "exclamationmark.triangle.fill"
        case .resolved: return "checkmark.shield.fill"
        }
    }
    
    var color: String {
        switch self {
        case .idle: return "green"
        case .monitoring: return "orange"
        case .panic: return "red"
        case .resolved: return "green"
        }
    }
}

// MARK: - Widget Intents

/// Intent for check-in button - confirms user is safe
/// Simplified version for widget that just performs the action
struct CheckInIntent: AppIntent {
    static let title: LocalizedStringResource = "Check In"
    static let description: IntentDescription = "Confirm you are safe"
    
    func perform() async throws -> some IntentResult {
        // Update last check-in time via shared UserDefaults
        UserDefaults.shared.set(Date(), forKey: "lastCheckInTime")
        return .result()
    }
}

/// Intent for the panic button - escalates to full emergency mode
struct PanicButtonIntent: AppIntent {
    static let title: LocalizedStringResource = "Panic Alert"
    static let description: IntentDescription = "Trigger emergency panic alert"
    
    // Opens app to handle full panic mode activation
    static var openAppWhenRun: Bool { true }
    
    func perform() async throws -> some IntentResult {
        // Set flag for app to pick up
        UserDefaults.shared.set(true, forKey: "pendingPanicActivation")
        return .result()
    }
}

/// Intent to stop all monitoring and resolve alerts
struct StopMonitoringIntent: AppIntent {
    static let title: LocalizedStringResource = "Stop Monitoring"
    static let description: IntentDescription = "Stop safety monitoring and resolve any alerts"
    
    // Opens app to handle cleanup
    static var openAppWhenRun: Bool { true }
    
    func perform() async throws -> some IntentResult {
        // Set flag for app to pick up
        UserDefaults.shared.set(true, forKey: "pendingStopMonitoring")
        return .result()
    }
}

/// Intent to toggle safety monitoring on/off
struct ToggleSafetyMonitoringIntent: AppIntent {
    static let title: LocalizedStringResource = "Toggle Safety Monitoring"
    static let description: IntentDescription = "Start or stop safety monitoring"
    
    // Opens app to establish background location session
    static var openAppWhenRun: Bool { true }
    
    func perform() async throws -> some IntentResult {
        // Toggle the monitoring state
        let isCurrentlyMonitoring = UserDefaults.shared.bool(forKey: "isMonitoringActive")
        UserDefaults.shared.set(!isCurrentlyMonitoring, forKey: "isMonitoringActive")
        UserDefaults.shared.set(true, forKey: "pendingMonitoringToggle")
        return .result()
    }
}

// MARK: - Shared UserDefaults

extension UserDefaults {
    /// Shared UserDefaults between app and widget via App Group
    static var shared: UserDefaults {
        // TODO: Update to match your App Group identifier in Xcode
        UserDefaults(suiteName: "group.com.sanctuary.app") ?? .standard
    }
}

// MARK: - Color Extension

extension Color {
    static let safetyOrange = Color(red: 1.0, green: 0.373, blue: 0.0)
}
