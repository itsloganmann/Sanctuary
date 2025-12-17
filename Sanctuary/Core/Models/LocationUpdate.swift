//
//  LocationUpdate.swift
//  Sanctuary
//
//  High-frequency location update model during active monitoring
//

import Foundation
import CoreLocation

/// Individual location update during active safety monitoring
struct LocationUpdate: Codable, Identifiable, Sendable {
    let id: UUID
    let alertId: UUID?
    let userId: UUID
    let latitude: Double
    let longitude: Double
    var accuracyMeters: Double?
    var altitude: Double?
    var speed: Double?
    var heading: Double?
    var batteryLevel: Double?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case alertId = "alert_id"
        case userId = "user_id"
        case latitude
        case longitude
        case accuracyMeters = "accuracy_meters"
        case altitude
        case speed
        case heading
        case batteryLevel = "battery_level"
        case createdAt = "created_at"
    }
    
    /// Current location as CLLocationCoordinate2D
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// Create from CLLocation
    static func from(
        location: CLLocation,
        userId: UUID,
        alertId: UUID? = nil,
        batteryLevel: Double? = nil
    ) -> LocationUpdate {
        LocationUpdate(
            id: UUID(),
            alertId: alertId,
            userId: userId,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            accuracyMeters: location.horizontalAccuracy,
            altitude: location.altitude,
            speed: location.speed >= 0 ? location.speed : nil,
            heading: location.course >= 0 ? location.course : nil,
            batteryLevel: batteryLevel,
            createdAt: location.timestamp
        )
    }
}
