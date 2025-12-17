//
//  SafetyAlertRepository.swift
//  Sanctuary
//
//  Repository for safety alert data access with realtime support
//

import Foundation

/// Repository for safety alert operations
actor SafetyAlertRepository {
    
    private let supabase: SupabaseClientWrapper
    
    init(supabase: SupabaseClientWrapper) {
        self.supabase = supabase
    }
    
    // MARK: - Read Operations
    
    /// Fetch alert by ID
    func get(id: UUID) async throws -> SafetyAlert? {
        let alerts: [SafetyAlert] = try await supabase.get(
            from: "safety_alerts",
            filters: ["id": "eq.\(id.uuidString)"],
            limit: 1
        )
        return alerts.first
    }
    
    /// Fetch active alerts for a user
    func getActiveAlerts(userId: UUID) async throws -> [SafetyAlert] {
        let alerts: [SafetyAlert] = try await supabase.get(
            from: "safety_alerts",
            filters: [
                "user_id": "eq.\(userId.uuidString)",
                "status": "eq.active"
            ],
            order: "created_at.desc"
        )
        return alerts
    }
    
    /// Fetch alert history
    func getAlertHistory(userId: UUID, limit: Int = 50) async throws -> [SafetyAlertSummary] {
        let alerts: [SafetyAlertSummary] = try await supabase.get(
            from: "safety_alerts",
            select: "id, alert_type, status, created_at, resolved_at",
            filters: ["user_id": "eq.\(userId.uuidString)"],
            order: "created_at.desc",
            limit: limit
        )
        return alerts
    }
    
    /// Fetch alerts visible to a trusted contact
    func getAlertsForTrustedContact(contactId: UUID) async throws -> [SafetyAlert] {
        // This relies on RLS policy allowing trusted contacts to read
        let alerts: [SafetyAlert] = try await supabase.get(
            from: "safety_alerts",
            filters: ["status": "eq.active"],
            order: "created_at.desc"
        )
        return alerts
    }
    
    // MARK: - Write Operations
    
    /// Create a new safety alert
    func create(_ alert: SafetyAlert) async throws -> SafetyAlert {
        let result: [SafetyAlert] = try await supabase.insert(
            into: "safety_alerts",
            values: alert
        )
        guard let created = result.first else {
            throw RepositoryError.insertFailed
        }
        return created
    }
    
    /// Update alert status
    func updateStatus(alertId: UUID, status: AlertStatus) async throws {
        struct StatusUpdate: Codable {
            let status: String
            let resolved_at: Date?
        }
        
        let resolvedAt = (status == .resolved || status == .falseAlarm) ? Date() : nil
        
        let _: [SafetyAlert] = try await supabase.update(
            table: "safety_alerts",
            values: StatusUpdate(
                status: status.rawValue,
                resolved_at: resolvedAt
            ),
            filters: ["id": "eq.\(alertId.uuidString)"]
        )
    }
    
    /// Update alert location
    func updateLocation(
        alertId: UUID,
        latitude: Double,
        longitude: Double,
        accuracy: Double?,
        altitude: Double?,
        speed: Double?,
        heading: Double?,
        batteryLevel: Double?
    ) async throws {
        struct LocationUpdate: Codable {
            let latitude: Double
            let longitude: Double
            let accuracy_meters: Double?
            let altitude: Double?
            let speed: Double?
            let heading: Double?
            let battery_level: Double?
        }
        
        let _: [SafetyAlert] = try await supabase.update(
            table: "safety_alerts",
            values: LocationUpdate(
                latitude: latitude,
                longitude: longitude,
                accuracy_meters: accuracy,
                altitude: altitude,
                speed: speed,
                heading: heading,
                battery_level: batteryLevel
            ),
            filters: ["id": "eq.\(alertId.uuidString)"]
        )
    }
    
    /// Append to location history
    func appendLocationHistory(alertId: UUID, location: LocationPoint) async throws {
        // Fetch current history
        guard var alert = try await get(id: alertId) else {
            throw RepositoryError.notFound
        }
        
        alert.locationHistory.append(location)
        
        struct HistoryUpdate: Codable {
            let location_history: [LocationPoint]
        }
        
        let _: [SafetyAlert] = try await supabase.update(
            table: "safety_alerts",
            values: HistoryUpdate(location_history: alert.locationHistory),
            filters: ["id": "eq.\(alertId.uuidString)"]
        )
    }
    
    /// Escalate alert to 911
    func escalateTo911(alertId: UUID) async throws {
        struct EscalationUpdate: Codable {
            let status: String
            let escalated_to_911: Bool
        }
        
        let _: [SafetyAlert] = try await supabase.update(
            table: "safety_alerts",
            values: EscalationUpdate(
                status: AlertStatus.escalated.rawValue,
                escalated_to_911: true
            ),
            filters: ["id": "eq.\(alertId.uuidString)"]
        )
    }
    
    /// Resolve alert as false alarm
    func resolveAsFalseAlarm(alertId: UUID) async throws {
        try await updateStatus(alertId: alertId, status: .falseAlarm)
    }
    
    // MARK: - Location Updates Table
    
    /// Insert a location update (for high-frequency tracking)
    func insertLocationUpdate(_ update: LocationUpdate) async throws {
        let _: [LocationUpdate] = try await supabase.insert(
            into: "location_updates",
            values: update
        )
    }
}
