//
//  AppState.swift
//  Sanctuary
//
//  Centralized observable app state (replaces DependencyContainer + Supabase)
//

import SwiftUI
import Observation

/// Centralized state for the entire app playground.
/// In the production app this is backed by Supabase;
/// here everything runs offline with mock data.
@Observable
@MainActor
final class AppState {
    
    // MARK: - Auth
    var isAuthenticated = false
    var currentUser: MockUser? = nil
    
    // MARK: - Safety
    var isPanicModeActive = false
    var isMonitoring = false
    var holdProgress: CGFloat = 0
    var monitoringStartTime: Date? = nil
    var locationHistory: [MockLocation] = []
    var checkInCount = 0
    
    // MARK: - Consent
    var agreements: [MockAgreement] = MockAgreement.samples
    var boundaryCards: [BoundaryCard] = BoundaryCard.defaultCards
    
    // MARK: - Contacts
    var trustedContacts: [TrustedContact] = TrustedContact.samples
    
    // MARK: - Settings
    var emergencyMessage = "I need help. This is an emergency."
    var checkInIntervalMinutes = 30
    var isStealthModeEnabled = false
    
    // MARK: - Onboarding
    var hasCompletedOnboarding = false
    
    // MARK: - Actions
    
    func signIn(name: String) {
        currentUser = MockUser(displayName: name)
        isAuthenticated = true
    }
    
    func signOut() {
        isAuthenticated = false
        currentUser = nil
        isPanicModeActive = false
        isMonitoring = false
    }
    
    func activatePanicMode() {
        isPanicModeActive = true
        isMonitoring = true
        monitoringStartTime = Date()
        
        // Simulate location broadcasting
        let baseLat = 34.4140
        let baseLng = -119.8489
        for i in 0..<5 {
            locationHistory.append(MockLocation(
                latitude: baseLat + Double.random(in: -0.002...0.002),
                longitude: baseLng + Double.random(in: -0.002...0.002),
                timestamp: Date().addingTimeInterval(TimeInterval(-i * 30)),
                accuracy: Double.random(in: 3...15)
            ))
        }
    }
    
    func deactivatePanicMode() {
        isPanicModeActive = false
        isMonitoring = false
        monitoringStartTime = nil
        locationHistory.removeAll()
    }
    
    func checkIn() {
        checkInCount += 1
    }
}

// MARK: - Mock Models

struct MockUser: Identifiable, Sendable {
    let id = UUID()
    var displayName: String
    var phone: String = "(408) 555-0199"
}

struct MockLocation: Identifiable, Sendable {
    let id = UUID()
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let accuracy: Double
}

struct TrustedContact: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let phone: String
    let relation: String
    let isNotified: Bool
    
    static let samples: [TrustedContact] = [
        TrustedContact(name: "Mom", phone: "(408) 555-0101", relation: "Family", isNotified: false),
        TrustedContact(name: "Sarah K.", phone: "(415) 555-0142", relation: "Friend", isNotified: false),
        TrustedContact(name: "Campus Safety", phone: "(805) 893-3446", relation: "Emergency", isNotified: false)
    ]
}

struct MockAgreement: Identifiable, Sendable {
    let id = UUID()
    let partnerName: String
    let status: String
    let boundaryCount: Int
    let createdAt: Date
    
    static let samples: [MockAgreement] = [
        MockAgreement(partnerName: "Alex", status: "Active", boundaryCount: 6, createdAt: Date().addingTimeInterval(-86400 * 7)),
        MockAgreement(partnerName: "Jordan", status: "Pending", boundaryCount: 8, createdAt: Date().addingTimeInterval(-3600))
    ]
}
