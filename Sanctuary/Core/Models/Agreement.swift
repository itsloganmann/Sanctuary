//
//  Agreement.swift
//  Sanctuary
//
//  Consent agreement model for boundary communication
//

import Foundation

/// Status of a consent agreement
enum AgreementStatus: String, Codable, Sendable {
    case pending
    case active
    case expired
    case revoked
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .active: return "Active"
        case .expired: return "Expired"
        case .revoked: return "Revoked"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "yellow"
        case .active: return "green"
        case .expired: return "gray"
        case .revoked: return "red"
        }
    }
}

/// Individual boundary within an agreement
struct Boundary: Codable, Sendable, Equatable, Identifiable {
    var id: String { category }
    let category: String
    var consent: Bool
    var note: String?
    
    static let defaultCategories = [
        "Photos & Videos",
        "Staying Overnight",
        "Physical Intimacy",
        "Sharing Location",
        "Meeting Friends",
        "Social Media Posts",
        "Alcohol/Substances",
        "Private Conversations"
    ]
}

/// Consent agreement between two users
struct Agreement: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    let initiatorId: UUID
    let partnerId: UUID
    var status: AgreementStatus
    var boundaries: [Boundary]
    var expiresAt: Date?
    var revokedAt: Date?
    var revokedBy: UUID?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case initiatorId = "initiator_id"
        case partnerId = "partner_id"
        case status
        case boundaries
        case expiresAt = "expires_at"
        case revokedAt = "revoked_at"
        case revokedBy = "revoked_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// Check if the agreement is currently valid
    var isValid: Bool {
        guard status == .active else { return false }
        if let expiresAt = expiresAt, expiresAt < Date() {
            return false
        }
        return true
    }
    
    /// Get boundaries that have consent
    var consentedBoundaries: [Boundary] {
        boundaries.filter { $0.consent }
    }
    
    /// Get boundaries that do not have consent
    var declinedBoundaries: [Boundary] {
        boundaries.filter { !$0.consent }
    }
    
    /// Create a new pending agreement
    static func new(initiatorId: UUID, partnerId: UUID, boundaries: [Boundary] = []) -> Agreement {
        Agreement(
            id: UUID(),
            initiatorId: initiatorId,
            partnerId: partnerId,
            status: .pending,
            boundaries: boundaries,
            expiresAt: nil,
            revokedAt: nil,
            revokedBy: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    /// Create default boundaries for a new agreement
    static func defaultBoundaries() -> [Boundary] {
        Boundary.defaultCategories.map { category in
            Boundary(category: category, consent: false, note: nil)
        }
    }
}

/// Agreement with partner profile info for display
struct AgreementWithPartner: Identifiable, Sendable {
    let agreement: Agreement
    let partner: ProfileSummary
    
    var id: UUID { agreement.id }
}
