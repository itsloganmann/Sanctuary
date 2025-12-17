//
//  SafetyActivityAttributes.swift
//  Sanctuary
//
//  Live Activity attributes for safety monitoring display on lock screen
//

import ActivityKit
import Foundation

/// Attributes for Safety Monitoring Live Activity
///
/// Live Activities provide persistent lock screen presence during panic mode.
/// This is crucial for user visibility and quick access to safety controls.
struct SafetyActivityAttributes: ActivityAttributes {
    
    /// Static data that doesn't change during the activity
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
