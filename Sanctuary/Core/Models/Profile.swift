//
//  Profile.swift
//  Sanctuary
//
//  User profile model matching Supabase schema
//

import Foundation

/// User profile stored in Supabase
struct Profile: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    var phoneNumber: String?
    var displayName: String
    var avatarUrl: String?
    var emergencyMessage: String
    var isMonitoringEnabled: Bool
    var checkInIntervalMinutes: Int
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case phoneNumber = "phone_number"
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case emergencyMessage = "emergency_message"
        case isMonitoringEnabled = "is_monitoring_enabled"
        case checkInIntervalMinutes = "check_in_interval_minutes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// Create a new profile for a user
    static func new(id: UUID, displayName: String, phoneNumber: String? = nil) -> Profile {
        Profile(
            id: id,
            phoneNumber: phoneNumber,
            displayName: displayName,
            avatarUrl: nil,
            emergencyMessage: "I need help. This is an emergency.",
            isMonitoringEnabled: false,
            checkInIntervalMinutes: 30,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

/// Minimal profile info for display purposes
struct ProfileSummary: Codable, Identifiable, Sendable {
    let id: UUID
    let displayName: String
    let avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
    }
}
