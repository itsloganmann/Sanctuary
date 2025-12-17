//
//  AgreementRepository.swift
//  Sanctuary
//
//  Repository for consent agreement data access
//

import Foundation

/// Repository for consent agreement operations
actor AgreementRepository {
    
    private let supabase: SupabaseClientWrapper
    
    init(supabase: SupabaseClientWrapper) {
        self.supabase = supabase
    }
    
    // MARK: - Read Operations
    
    /// Fetch agreement by ID
    func get(id: UUID) async throws -> Agreement? {
        let agreements: [Agreement] = try await supabase.get(
            from: "agreements",
            filters: ["id": "eq.\(id.uuidString)"],
            limit: 1
        )
        return agreements.first
    }
    
    /// Fetch all active agreements for a user (as initiator or partner)
    func getActiveAgreements(userId: UUID) async throws -> [Agreement] {
        // We need to fetch agreements where user is either initiator or partner
        // and status is active
        let asInitiator: [Agreement] = try await supabase.get(
            from: "agreements",
            filters: [
                "initiator_id": "eq.\(userId.uuidString)",
                "status": "eq.active"
            ]
        )
        
        let asPartner: [Agreement] = try await supabase.get(
            from: "agreements",
            filters: [
                "partner_id": "eq.\(userId.uuidString)",
                "status": "eq.active"
            ]
        )
        
        // Combine and deduplicate
        var uniqueAgreements: [UUID: Agreement] = [:]
        for agreement in asInitiator + asPartner {
            uniqueAgreements[agreement.id] = agreement
        }
        
        return Array(uniqueAgreements.values).sorted { $0.createdAt > $1.createdAt }
    }
    
    /// Fetch pending agreements for a user
    func getPendingAgreements(userId: UUID) async throws -> [Agreement] {
        let agreements: [Agreement] = try await supabase.get(
            from: "agreements",
            filters: [
                "partner_id": "eq.\(userId.uuidString)",
                "status": "eq.pending"
            ],
            order: "created_at.desc"
        )
        return agreements
    }
    
    /// Fetch agreement history (all statuses)
    func getAgreementHistory(userId: UUID, limit: Int = 20) async throws -> [Agreement] {
        let asInitiator: [Agreement] = try await supabase.get(
            from: "agreements",
            filters: ["initiator_id": "eq.\(userId.uuidString)"],
            order: "created_at.desc",
            limit: limit
        )
        
        let asPartner: [Agreement] = try await supabase.get(
            from: "agreements",
            filters: ["partner_id": "eq.\(userId.uuidString)"],
            order: "created_at.desc",
            limit: limit
        )
        
        var uniqueAgreements: [UUID: Agreement] = [:]
        for agreement in asInitiator + asPartner {
            uniqueAgreements[agreement.id] = agreement
        }
        
        return Array(uniqueAgreements.values)
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(limit)
            .map { $0 }
    }
    
    // MARK: - Write Operations
    
    /// Create a new agreement
    func create(_ agreement: Agreement) async throws -> Agreement {
        let result: [Agreement] = try await supabase.insert(
            into: "agreements",
            values: agreement
        )
        guard let created = result.first else {
            throw RepositoryError.insertFailed
        }
        return created
    }
    
    /// Accept a pending agreement
    func accept(agreementId: UUID) async throws -> Agreement {
        struct StatusUpdate: Codable {
            let status: String
        }
        
        let result: [Agreement] = try await supabase.update(
            table: "agreements",
            values: StatusUpdate(status: "active"),
            filters: ["id": "eq.\(agreementId.uuidString)"]
        )
        guard let updated = result.first else {
            throw RepositoryError.updateFailed
        }
        return updated
    }
    
    /// Revoke an agreement
    func revoke(agreementId: UUID, revokedBy: UUID) async throws {
        struct RevokeUpdate: Codable {
            let status: String
            let revoked_at: Date
            let revoked_by: UUID
        }
        
        let _: [Agreement] = try await supabase.update(
            table: "agreements",
            values: RevokeUpdate(
                status: "revoked",
                revoked_at: Date(),
                revoked_by: revokedBy
            ),
            filters: ["id": "eq.\(agreementId.uuidString)"]
        )
    }
    
    /// Update boundaries in an agreement
    func updateBoundaries(agreementId: UUID, boundaries: [Boundary]) async throws -> Agreement {
        struct BoundaryUpdate: Codable {
            let boundaries: [Boundary]
        }
        
        let result: [Agreement] = try await supabase.update(
            table: "agreements",
            values: BoundaryUpdate(boundaries: boundaries),
            filters: ["id": "eq.\(agreementId.uuidString)"]
        )
        guard let updated = result.first else {
            throw RepositoryError.updateFailed
        }
        return updated
    }
}
