//
//  ContactRelation.swift
//  Sanctuary
//
//  Trusted contact relationships model
//

import Foundation

/// Type of relationship between user and trusted contact
enum RelationType: String, Codable, Sendable, CaseIterable {
    case emergency
    case partner
    case friend
    case family
    
    var displayName: String {
        switch self {
        case .emergency: return "Emergency Contact"
        case .partner: return "Partner"
        case .friend: return "Friend"
        case .family: return "Family"
        }
    }
    
    var icon: String {
        switch self {
        case .emergency: return "cross.circle.fill"
        case .partner: return "heart.fill"
        case .friend: return "person.2.fill"
        case .family: return "house.fill"
        }
    }
}

/// Relationship between a user and their trusted contact
struct ContactRelation: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    let userId: UUID
    let trustedContactId: UUID
    var relationType: RelationType
    var isActive: Bool
    var canViewLocation: Bool
    var canReceiveAlerts: Bool
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case trustedContactId = "trusted_contact_id"
        case relationType = "relation_type"
        case isActive = "is_active"
        case canViewLocation = "can_view_location"
        case canReceiveAlerts = "can_receive_alerts"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// Create a new contact relation
    static func new(
        userId: UUID,
        trustedContactId: UUID,
        relationType: RelationType
    ) -> ContactRelation {
        ContactRelation(
            id: UUID(),
            userId: userId,
            trustedContactId: trustedContactId,
            relationType: relationType,
            isActive: true,
            canViewLocation: true,
            canReceiveAlerts: true,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

/// Extended contact info with profile details
struct TrustedContact: Codable, Identifiable, Sendable {
    let id: UUID
    let displayName: String
    let phoneNumber: String?
    let relationType: RelationType
    
    enum CodingKeys: String, CodingKey {
        case id = "contact_id"
        case displayName = "display_name"
        case phoneNumber = "phone_number"
        case relationType = "relation_type"
    }
}
