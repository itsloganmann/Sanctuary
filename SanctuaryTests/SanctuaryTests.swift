//
//  SanctuaryTests.swift
//  SanctuaryTests
//
//  Unit tests for Sanctuary app
//

import XCTest
@testable import Sanctuary

final class SanctuaryTests: XCTestCase {
    
    // MARK: - Model Tests
    
    func testProfileCreation() {
        let userId = UUID()
        let profile = Profile.new(id: userId, displayName: "Test User", phoneNumber: "+15551234567")
        
        XCTAssertEqual(profile.id, userId)
        XCTAssertEqual(profile.displayName, "Test User")
        XCTAssertEqual(profile.phoneNumber, "+15551234567")
        XCTAssertEqual(profile.emergencyMessage, "I need help. This is an emergency.")
        XCTAssertFalse(profile.isMonitoringEnabled)
        XCTAssertEqual(profile.checkInIntervalMinutes, 30)
    }
    
    func testAgreementCreation() {
        let initiatorId = UUID()
        let partnerId = UUID()
        let agreement = Agreement.new(initiatorId: initiatorId, partnerId: partnerId)
        
        XCTAssertEqual(agreement.initiatorId, initiatorId)
        XCTAssertEqual(agreement.partnerId, partnerId)
        XCTAssertEqual(agreement.status, .pending)
        XCTAssertTrue(agreement.boundaries.isEmpty)
    }
    
    func testAgreementDefaultBoundaries() {
        let boundaries = Agreement.defaultBoundaries()
        
        XCTAssertEqual(boundaries.count, 8)
        XCTAssertTrue(boundaries.contains { $0.category == "Photos & Videos" })
        XCTAssertTrue(boundaries.allSatisfy { !$0.consent })
    }
    
    func testAgreementValidity() {
        let initiatorId = UUID()
        let partnerId = UUID()
        var agreement = Agreement.new(initiatorId: initiatorId, partnerId: partnerId)
        
        // Pending agreement is not valid
        XCTAssertFalse(agreement.isValid)
        
        // Active agreement is valid
        agreement = Agreement(
            id: UUID(),
            initiatorId: initiatorId,
            partnerId: partnerId,
            status: .active,
            boundaries: [],
            expiresAt: nil,
            revokedAt: nil,
            revokedBy: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        XCTAssertTrue(agreement.isValid)
        
        // Expired agreement is not valid
        agreement = Agreement(
            id: UUID(),
            initiatorId: initiatorId,
            partnerId: partnerId,
            status: .active,
            boundaries: [],
            expiresAt: Date().addingTimeInterval(-3600), // 1 hour ago
            revokedAt: nil,
            revokedBy: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        XCTAssertFalse(agreement.isValid)
    }
    
    func testSafetyAlertCreation() {
        let userId = UUID()
        let alert = SafetyAlert.newPanic(userId: userId, location: nil, batteryLevel: 0.85)
        
        XCTAssertEqual(alert.userId, userId)
        XCTAssertEqual(alert.alertType, .panic)
        XCTAssertEqual(alert.status, .active)
        XCTAssertEqual(alert.batteryLevel, 0.85)
        XCTAssertFalse(alert.escalatedTo911)
    }
    
    func testLinkingCodeGeneration() {
        let userId = UUID()
        let code = LinkingCode.new(userId: userId, purpose: .partnerLink)
        
        XCTAssertEqual(code.userId, userId)
        XCTAssertEqual(code.purpose, .partnerLink)
        XCTAssertEqual(code.code.count, 6)
        XCTAssertTrue(code.isValid)
        XCTAssertNil(code.usedAt)
    }
    
    func testLinkingCodeExpiration() {
        let userId = UUID()
        let expiredCode = LinkingCode(
            id: UUID(),
            userId: userId,
            code: "ABC123",
            purpose: .partnerLink,
            expiresAt: Date().addingTimeInterval(-60), // Expired
            usedAt: nil,
            usedBy: nil,
            createdAt: Date()
        )
        
        XCTAssertFalse(expiredCode.isValid)
        XCTAssertEqual(expiredCode.timeRemaining, 0)
    }
    
    // MARK: - Boundary Tests
    
    func testBoundaryFiltering() {
        let boundaries = [
            Boundary(category: "Photos", consent: true, note: nil),
            Boundary(category: "Location", consent: false, note: nil),
            Boundary(category: "Overnight", consent: true, note: "Weekends only"),
        ]
        
        let agreement = Agreement(
            id: UUID(),
            initiatorId: UUID(),
            partnerId: UUID(),
            status: .active,
            boundaries: boundaries,
            expiresAt: nil,
            revokedAt: nil,
            revokedBy: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        XCTAssertEqual(agreement.consentedBoundaries.count, 2)
        XCTAssertEqual(agreement.declinedBoundaries.count, 1)
    }
    
    // MARK: - Contact Relation Tests
    
    func testContactRelationCreation() {
        let userId = UUID()
        let contactId = UUID()
        let relation = ContactRelation.new(
            userId: userId,
            trustedContactId: contactId,
            relationType: .emergency
        )
        
        XCTAssertEqual(relation.userId, userId)
        XCTAssertEqual(relation.trustedContactId, contactId)
        XCTAssertEqual(relation.relationType, .emergency)
        XCTAssertTrue(relation.isActive)
        XCTAssertTrue(relation.canViewLocation)
        XCTAssertTrue(relation.canReceiveAlerts)
    }
    
    func testRelationTypeDisplayNames() {
        XCTAssertEqual(RelationType.emergency.displayName, "Emergency Contact")
        XCTAssertEqual(RelationType.partner.displayName, "Partner")
        XCTAssertEqual(RelationType.friend.displayName, "Friend")
        XCTAssertEqual(RelationType.family.displayName, "Family")
    }
    
    // MARK: - Alert Type Tests
    
    func testAlertTypePriority() {
        XCTAssertEqual(AlertType.panic.priority, 3)
        XCTAssertEqual(AlertType.deadManSwitch.priority, 3)
        XCTAssertEqual(AlertType.checkInMissed.priority, 2)
        XCTAssertEqual(AlertType.manual.priority, 1)
    }
}
