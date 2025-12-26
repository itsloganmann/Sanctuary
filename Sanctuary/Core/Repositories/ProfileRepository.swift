// Used for inserts where no response body is expected
private struct EmptyResponse: Decodable {}
//
//  ProfileRepository.swift
//  Sanctuary
//
//  Repository for profile data access
//

import Foundation

/// Repository for profile CRUD operations
actor ProfileRepository {
    /// Remove a trusted contact relation for the given user
    func removeTrustedContact(for userId: UUID, contactId: UUID) async throws {
        try await supabase.delete(
            from: "contact_relations",
            filters: [
                "user_id": "eq.\(userId.uuidString)",
                "trusted_contact_id": "eq.\(contactId.uuidString)"
            ]
        )
    }

    /// Fetch trusted contacts for the given user
    func getTrustedContacts(for userId: UUID) async throws -> [TrustedContact] {
        print("getTrustedContacts called for userId: \(userId)")
        do {
            // Fetch the raw data from Supabase
            let url = SupabaseConfig.projectURL.appendingPathComponent("rest/v1/contact_relations")
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            urlComponents.queryItems = [
                URLQueryItem(name: "select", value: "trusted_contact_id,relation_type,profiles!contact_relations_trusted_contact_id_fkey(id,display_name,phone_number)"),
                URLQueryItem(name: "user_id", value: "eq.\(userId.uuidString)")
            ]
            var request = URLRequest(url: urlComponents.url!)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                print("[ProfileRepository] HTTP status: \(httpResponse.statusCode)")
            }
            if let rawJSONString = String(data: data, encoding: .utf8) {
                print("[ProfileRepository] Raw JSON from Supabase: \(rawJSONString)")
            } else {
                print("[ProfileRepository] Could not decode data to UTF-8 string")
            }
            do {
                let contacts = try JSONDecoder.supabase.decode([TrustedContact].self, from: data)
                print("[ProfileRepository] Decoded trusted contacts: \(contacts)")
                return contacts
            } catch let decodeError {
                print("[ProfileRepository] Decoding error: \(String(describing: decodeError))")
                throw decodeError
            }
        } catch {
            print("Error fetching trusted contacts: \(String(describing: error))")
            throw error
        }
    }

    /// Add a trusted contact (creates a new profile and contact relation)
    func addTrustedContact(for userId: UUID, displayName: String, phoneNumber: String) async throws -> Profile {
        // 1. Create profile for contact (if not exists)
        var contactProfile: Profile
        if let existing = try await getByPhone(phoneNumber) {
            contactProfile = existing
        } else {
            let newProfile = Profile(
                id: UUID(),
                phoneNumber: phoneNumber,
                displayName: displayName,
                avatarUrl: nil,
                emergencyMessage: "I need help. This is an emergency.",
                isMonitoringEnabled: false,
                checkInIntervalMinutes: 30,
                createdAt: Date(),
                updatedAt: Date()
            )
            contactProfile = try await create(newProfile)
        }
        // 2. Create contact relation
        let relation = ContactRelationInsert(
            userId: userId,
            trustedContactId: contactProfile.id,
            relationType: "emergency",
            isActive: true,
            canViewLocation: true,
            canReceiveAlerts: true
        )
        do {
            // Insert and use EmptyResponse to satisfy Decodable requirement
            let _: EmptyResponse = try await supabase.insert(
                into: "contact_relations",
                values: relation
            )
            print("[ProfileRepository] Inserted contact relation for userId: \(userId), trustedContactId: \(contactProfile.id)")
        } catch {
            print("[ProfileRepository] Failed to insert contact relation: \(error)")
            throw error
        }
        return contactProfile
    }
    
    private let supabase: SupabaseClientWrapper

    // Helper struct for contact_relations insert
    struct ContactRelationInsert: Codable {
        let userId: UUID
        let trustedContactId: UUID
        let relationType: String
        let isActive: Bool
        let canViewLocation: Bool
        let canReceiveAlerts: Bool

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case trustedContactId = "trusted_contact_id"
            case relationType = "relation_type"
            case isActive = "is_active"
            case canViewLocation = "can_view_location"
            case canReceiveAlerts = "can_receive_alerts"
        }
    }
    
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
        let updates = ProfileFieldUpdate(
            displayName: displayName,
            emergencyMessage: emergencyMessage,
            isMonitoringEnabled: isMonitoringEnabled,
            checkInIntervalMinutes: checkInIntervalMinutes
        )
        
        // Check if there are any updates
        guard displayName != nil || emergencyMessage != nil || 
              isMonitoringEnabled != nil || checkInIntervalMinutes != nil else { return }
        
        let _: [Profile] = try await supabase.update(
            table: "profiles",
            values: updates,
            filters: ["id": "eq.\(id.uuidString)"]
        )
    }
}

// MARK: - Profile Field Update (for partial updates)

private struct ProfileFieldUpdate: Encodable {
    let displayName: String?
    let emergencyMessage: String?
    let isMonitoringEnabled: Bool?
    let checkInIntervalMinutes: Int?
    
    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case emergencyMessage = "emergency_message"
        case isMonitoringEnabled = "is_monitoring_enabled"
        case checkInIntervalMinutes = "check_in_interval_minutes"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // Only encode non-nil values
        if let displayName = displayName {
            try container.encode(displayName, forKey: .displayName)
        }
        if let emergencyMessage = emergencyMessage {
            try container.encode(emergencyMessage, forKey: .emergencyMessage)
        }
        if let isMonitoringEnabled = isMonitoringEnabled {
            try container.encode(isMonitoringEnabled, forKey: .isMonitoringEnabled)
        }
        if let checkInIntervalMinutes = checkInIntervalMinutes {
            try container.encode(checkInIntervalMinutes, forKey: .checkInIntervalMinutes)
        }
    }
}

// MARK: - Repository Errors

enum RepositoryError: LocalizedError {
    case insertFailed
    case updateFailed
    case notFound
    case unauthorized
    case noData
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .insertFailed: return "Failed to insert record"
        case .updateFailed: return "Failed to update record"
        case .notFound: return "Record not found"
        case .unauthorized: return "Unauthorized access"
        case .noData: return "No data returned"
        case .decodingError(let error): return "Decoding error: \(error.localizedDescription)"
        }
    }
}
