//
//  LinkingCode.swift
//  Sanctuary
//
//  QR code linking model for partner/contact connections
//

import Foundation

/// Purpose of a linking code
enum LinkingPurpose: String, Codable, Sendable {
    case partnerLink = "partner_link"
    case emergencyContact = "emergency_contact"
    
    var displayName: String {
        switch self {
        case .partnerLink: return "Partner Link"
        case .emergencyContact: return "Emergency Contact"
        }
    }
}

/// Temporary linking code for QR-based connections
struct LinkingCode: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    let code: String
    let purpose: LinkingPurpose
    let expiresAt: Date
    var usedAt: Date?
    var usedBy: UUID?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case code
        case purpose
        case expiresAt = "expires_at"
        case usedAt = "used_at"
        case usedBy = "used_by"
        case createdAt = "created_at"
    }
    
    /// Check if the code is still valid
    var isValid: Bool {
        usedAt == nil && expiresAt > Date()
    }
    
    /// Time remaining until expiration
    var timeRemaining: TimeInterval {
        max(0, expiresAt.timeIntervalSinceNow)
    }
    
    /// Generate a new linking code
    static func new(userId: UUID, purpose: LinkingPurpose, expiresIn: TimeInterval = 300) -> LinkingCode {
        LinkingCode(
            id: UUID(),
            userId: userId,
            code: generateCode(),
            purpose: purpose,
            expiresAt: Date().addingTimeInterval(expiresIn),
            usedAt: nil,
            usedBy: nil,
            createdAt: Date()
        )
    }
    
    /// Generate a random 6-character alphanumeric code
    private static func generateCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Excluding confusing chars
        return String((0..<6).map { _ in characters.randomElement()! })
    }
}

/// Data encoded in QR code
struct QRLinkData: Codable, Sendable {
    let code: String
    let purpose: LinkingPurpose
    let userId: UUID
    
    /// Create URL for deep linking
    var deepLinkURL: URL? {
        var components = URLComponents()
        components.scheme = "sanctuary"
        components.host = "link"
        components.queryItems = [
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "purpose", value: purpose.rawValue)
        ]
        return components.url
    }
    
    /// Parse from deep link URL
    static func from(url: URL) -> QRLinkData? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == "sanctuary",
              components.host == "link",
              let queryItems = components.queryItems else {
            return nil
        }
        
        let params = Dictionary(uniqueKeysWithValues: queryItems.compactMap { item in
            item.value.map { (item.name, $0) }
        })
        
        guard let code = params["code"],
              let purposeRaw = params["purpose"],
              let purpose = LinkingPurpose(rawValue: purposeRaw) else {
            return nil
        }
        
        // userId will be fetched from server using the code
        return QRLinkData(code: code, purpose: purpose, userId: UUID())
    }
}
