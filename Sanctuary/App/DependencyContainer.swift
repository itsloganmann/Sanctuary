//
//  DependencyContainer.swift
//  Sanctuary
//
//  Centralized dependency injection container for MVVM architecture
//

import SwiftUI
import Observation

/// Centralized container for all app dependencies
/// Uses @Observable for SwiftUI integration (iOS 17+)
@Observable
@MainActor
final class DependencyContainer {
    
    // MARK: - Singleton
    static let shared = DependencyContainer()
    
    // MARK: - Services
    let authManager: AuthManager
    let safetyLocationManager: SafetyLocationManager
    let hapticManager: HapticManager
    let supabaseClient: SupabaseClientWrapper
    
    // MARK: - Repositories
    let profileRepository: ProfileRepository
    let agreementRepository: AgreementRepository
    let safetyAlertRepository: SafetyAlertRepository
    
    // MARK: - App State
    var isAuthenticated: Bool = false
    var isPanicModeActive: Bool = false
    var isStealthModeEnabled: Bool = false
    
    // MARK: - Initialization
    private init() {
        // Initialize Supabase client first (required by other services)
        self.supabaseClient = SupabaseClientWrapper()
        
        // Initialize core services
        self.authManager = AuthManager(supabase: supabaseClient)
        self.safetyLocationManager = SafetyLocationManager()
        self.hapticManager = HapticManager()
        
        // Initialize repositories
        self.profileRepository = ProfileRepository(supabase: supabaseClient)
        self.agreementRepository = AgreementRepository(supabase: supabaseClient)
        self.safetyAlertRepository = SafetyAlertRepository(supabase: supabaseClient)
        
        // Setup auth state observation
        Task {
            await observeAuthState()
        }
    }
    
    // MARK: - Auth State Observation
    private func observeAuthState() async {
        for await state in authManager.authStateStream {
            self.isAuthenticated = state != nil
        }
    }
    
    // MARK: - Safety Actions
    func activatePanicMode() async throws {
        hapticManager.heavyImpact()
        try await safetyLocationManager.startPanicMode()
        isPanicModeActive = true
    }
    
    func deactivatePanicMode() async {
        await safetyLocationManager.stopPanicMode()
        isPanicModeActive = false
    }
    
    func toggleStealthMode() {
        isStealthModeEnabled.toggle()
        hapticManager.lightImpact()
    }
}
