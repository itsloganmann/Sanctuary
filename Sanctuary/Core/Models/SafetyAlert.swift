//
//  SafetyAlert.swift
//  Sanctuary
//
//  Safety alert model for emergency broadcasts
//

import Foundation
import CoreLocation

/// Type of safety alert triggered
enum AlertType: String, Codable, Sendable {
    case panic = "panic"
    case deadManSwitch = "dead_man_switch"
    case checkInMissed = "check_in_missed"
    case manual = "manual"
    
    var displayName: String {
        switch self {
        case .panic: return "Panic Alert"
        case .deadManSwitch: return "Dead Man's Switch"
        case .checkInMissed: return "Missed Check-In"
        case .manual: return "Manual Alert"
        }
    }
    
    var icon: String {
        switch self {
        case .panic: return "exclamationmark.triangle.fill"
        case .deadManSwitch: return "timer"
        case .checkInMissed: return "clock.badge.exclamationmark"
        case .manual: return "bell.fill"
        }
    }
    
    var priority: Int {
        switch self {
        case .panic: return 3
        case .deadManSwitch: return 3
        case .checkInMissed: return 2
        case .manual: return 1
        }
    }
}

/// Current status of a safety alert
enum AlertStatus: String, Codable, Sendable {
    case active
    case resolved
    case falseAlarm = "false_alarm"
    case escalated
    
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .resolved: return "Resolved"
        case .falseAlarm: return "False Alarm"
        case .escalated: return "Escalated to 911"
        }
    }
}

/// Historical location point during an alert
struct LocationPoint: Codable, Sendable {
    let lat: Double
    let lng: Double
    let timestamp: Date
    let accuracy: Double?
    
    init(from location: CLLocation) {
        self.lat = location.coordinate.latitude
        self.lng = location.coordinate.longitude
        self.timestamp = location.timestamp
        self.accuracy = location.horizontalAccuracy
    }
    
    init(lat: Double, lng: Double, timestamp: Date, accuracy: Double?) {
        self.lat = lat
        self.lng = lng
        self.timestamp = timestamp
        self.accuracy = accuracy
    }
}

/// Safety alert record for emergency situations
struct SafetyAlert: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    let userId: UUID
    let alertType: AlertType
    var status: AlertStatus
    var latitude: Double?
    var longitude: Double?
    var accuracyMeters: Double?
    var altitude: Double?
    var speed: Double?
    var heading: Double?
    var batteryLevel: Double?
    var customMessage: String?
    var locationHistory: [LocationPoint]
    var escalatedTo911: Bool
    var resolvedAt: Date?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case alertType = "alert_type"
        case status
        case latitude
        case longitude
        case accuracyMeters = "accuracy_meters"
        case altitude
        case speed
        case heading
        case batteryLevel = "battery_level"
        case customMessage = "custom_message"
        case locationHistory = "location_history"
        case escalatedTo911 = "escalated_to_911"
        case resolvedAt = "resolved_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// Current location as CLLocationCoordinate2D
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lng = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
    
    /// Duration since alert was created
    var duration: TimeInterval {
        Date().timeIntervalSince(createdAt)
    }
    
    /// Create a new panic alert
    static func newPanic(userId: UUID, location: CLLocation?, batteryLevel: Double? = nil) -> SafetyAlert {
        SafetyAlert(
            id: UUID(),
            userId: userId,
            alertType: .panic,
            status: .active,
            latitude: location?.coordinate.latitude,
            longitude: location?.coordinate.longitude,
            accuracyMeters: location?.horizontalAccuracy,
            altitude: location?.altitude,
            speed: location?.speed,
            heading: location?.course,
            batteryLevel: batteryLevel,
            customMessage: nil,
            locationHistory: location.map { [LocationPoint(from: $0)] } ?? [],
            escalatedTo911: false,
            resolvedAt: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    static func == (lhs: SafetyAlert, rhs: SafetyAlert) -> Bool {
        lhs.id == rhs.id && lhs.status == rhs.status && lhs.updatedAt == rhs.updatedAt
    }
}

/// Minimal alert info for list display
struct SafetyAlertSummary: Codable, Identifiable, Sendable {
    let id: UUID
    let alertType: AlertType
    let status: AlertStatus
    let createdAt: Date
    let resolvedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case alertType = "alert_type"
        case status
        case createdAt = "created_at"
        case resolvedAt = "resolved_at"
    }
}
