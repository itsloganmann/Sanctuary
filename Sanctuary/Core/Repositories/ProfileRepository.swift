//
//  ProfileRepository.swift
//  Sanctuary
//
//  Repository for profile data access
//

import Foundation

/// Repository for profile CRUD operations
actor ProfileRepository {
    
    private let supabase: SupabaseClientWrapper
    
    init(supabase: SupabaseClientWrapper) {
        self.supabase = supabase
    }
    
    // MARK: - Read Operations
    
    /// Fetch profile by ID
    func get(id: UUID) async throws -> Profile? {
        let profiles: [Profile] = try await supabase.get(
            from: "profiles",
            filters: ["id": "eq.\(id.uuidString)"],
            limit: 1
        )
        return profiles.first
    }
    
    /// Fetch profile by phone number
    func getByPhone(_ phoneNumber: String) async throws -> Profile? {
        let profiles: [Profile] = try await supabase.get(
            from: "profiles",
            filters: ["phone_number": "eq.\(phoneNumber)"],
            limit: 1
        )
        return profiles.first
    }
    
    // MARK: - Write Operations
    
    /// Create a new profile
    func create(_ profile: Profile) async throws -> Profile {
        let result: [Profile] = try await supabase.insert(
            into: "profiles",
            values: profile
        )
        guard let created = result.first else {
            throw RepositoryError.insertFailed
        }
        return created
    }
    
    /// Update an existing profile
    func update(_ profile: Profile) async throws -> Profile {
        let result: [Profile] = try await supabase.update(
            table: "profiles",
            values: profile,
            filters: ["id": "eq.\(profile.id.uuidString)"]
        )
        guard let updated = result.first else {
            throw RepositoryError.updateFailed
        }
        return updated
    }
    
    /// Update specific fields
    func updateFields(
        id: UUID,
        displayName: String? = nil,
        emergencyMessage: String? = nil,
        isMonitoringEnabled: Bool? = nil,
        checkInIntervalMinutes: Int? = nil
    ) async throws {
        var updates: [String: Any] = [:]
        
        if let displayName = displayName {
            updates["display_name"] = displayName
        }
        if let emergencyMessage = emergencyMessage {
            updates["emergency_message"] = emergencyMessage
        }
        if let isMonitoringEnabled = isMonitoringEnabled {
            updates["is_monitoring_enabled"] = isMonitoringEnabled
        }
        if let checkInIntervalMinutes = checkInIntervalMinutes {
            updates["check_in_interval_minutes"] = checkInIntervalMinutes
        }
        
        guard !updates.isEmpty else { return }
        
        let _: [Profile] = try await supabase.update(
            table: "profiles",
            values: updates,
            filters: ["id": "eq.\(id.uuidString)"]
        )
    }
}

// MARK: - Repository Errors

enum RepositoryError: LocalizedError {
    case insertFailed
    case updateFailed
    case notFound
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .insertFailed: return "Failed to insert record"
        case .updateFailed: return "Failed to update record"
        case .notFound: return "Record not found"
        case .unauthorized: return "Unauthorized access"
        }
    }
}
