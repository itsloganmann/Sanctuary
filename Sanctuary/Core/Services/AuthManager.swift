//
//  AuthManager.swift
//  Sanctuary
//
//  Authentication manager using Supabase Auth with Apple & Phone providers
//

import Foundation
import AuthenticationServices

/// Current authentication state
enum AuthState: Sendable {
    case unauthenticated
    case authenticating
    case authenticated(User)
    case error(String)
}

/// Authenticated user info
struct User: Codable, Identifiable, Sendable {
    let id: UUID
    let email: String?
    let phone: String?
    let createdAt: Date
    var profile: Profile?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case phone
        case createdAt = "created_at"
    }
}

/// Singleton manager for authentication state
/// Uses @Observable for SwiftUI integration
@Observable
@MainActor
final class AuthManager: NSObject {
    
    // MARK: - Properties
    
    private let supabase: SupabaseClientWrapper
    
    var currentUser: User?
    var authState: AuthState = .unauthenticated
    var isAuthenticated: Bool { currentUser != nil }
    
    // MARK: - Async Stream for Auth State
    
    private var authStateContinuation: AsyncStream<User?>.Continuation?
    
    var authStateStream: AsyncStream<User?> {
        AsyncStream { continuation in
            self.authStateContinuation = continuation
            continuation.yield(self.currentUser)
        }
    }
    
    // MARK: - Initialization
    
    init(supabase: SupabaseClientWrapper) {
        self.supabase = supabase
        super.init()
        
        Task {
            await restoreSession()
        }
    }
    
    // MARK: - Session Management
    
    /// Restore session from keychain on app launch
    private func restoreSession() async {
        guard let sessionData = KeychainHelper.load(key: "supabase_session"),
              let session = try? JSONDecoder().decode(StoredSession.self, from: sessionData) else {
            return
        }
        
        // Check if token is expired
        if session.expiresAt > Date() {
            await supabase.setSession(accessToken: session.accessToken, refreshToken: session.refreshToken)
            
            // Fetch user profile
            await fetchCurrentUser(userId: session.userId)
        } else {
            // Try to refresh token
            await refreshSession(refreshToken: session.refreshToken)
        }
    }
    
    /// Refresh expired session
    private func refreshSession(refreshToken: String) async {
        // TODO: Implement token refresh via Supabase Auth API
        // For now, require re-authentication
        authState = .unauthenticated
    }
    
    /// Fetch current user and their profile
    private func fetchCurrentUser(userId: UUID) async {
        do {
            let profiles: [Profile] = try await supabase.get(
                from: "profiles",
                filters: ["id": "eq.\(userId.uuidString)"],
                limit: 1
            )
            
            if let profile = profiles.first {
                currentUser = User(
                    id: userId,
                    email: nil,
                    phone: profile.phoneNumber,
                    createdAt: profile.createdAt,
                    profile: profile
                )
                authState = .authenticated(currentUser!)
                authStateContinuation?.yield(currentUser)
            }
        } catch {
            print("Error fetching user profile: \(error)")
            authState = .error(error.localizedDescription)
        }
    }
    
    // MARK: - Apple Sign In
    
    /// Sign in with Apple
    func signInWithApple() async throws {
        authState = .authenticating
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email, .fullName]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        
        let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ASAuthorization, Error>) in
            let delegate = AppleSignInDelegate(continuation: continuation)
            controller.delegate = delegate
            controller.performRequests()
            
            // Keep delegate alive
            objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
        }
        
        guard let credential = result.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw SupabaseError.authError("Failed to get Apple ID token")
        }
        
        // Exchange Apple token with Supabase
        try await authenticateWithProvider(
            provider: "apple",
            idToken: tokenString,
            nonce: nil
        )
    }
    
    // MARK: - Phone Authentication
    
    /// Send OTP to phone number
    func sendPhoneOTP(phoneNumber: String) async throws {
        authState = .authenticating
        
        // Call Supabase Auth API to send OTP
        let url = SupabaseConfig.projectURL.appendingPathComponent("auth/v1/otp")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        
        let body: [String: Any] = [
            "phone": phoneNumber,
            "channel": "sms"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.authError("Failed to send OTP")
        }
        
        authState = .unauthenticated // Waiting for OTP verification
    }
    
    /// Verify phone OTP
    func verifyPhoneOTP(phoneNumber: String, code: String) async throws {
        authState = .authenticating
        
        let url = SupabaseConfig.projectURL.appendingPathComponent("auth/v1/verify")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        
        let body: [String: Any] = [
            "phone": phoneNumber,
            "token": code,
            "type": "sms"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Verification failed"
            throw SupabaseError.authError(message)
        }
        
        // Parse session response
        let sessionResponse = try JSONDecoder.supabase.decode(AuthSessionResponse.self, from: data)
        
        // Store session
        await handleAuthSession(sessionResponse)
    }
    
    // MARK: - Provider Authentication
    
    private func authenticateWithProvider(provider: String, idToken: String, nonce: String?) async throws {
        let url = SupabaseConfig.projectURL.appendingPathComponent("auth/v1/token")
        
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [URLQueryItem(name: "grant_type", value: "id_token")]
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        
        var body: [String: Any] = [
            "provider": provider,
            "id_token": idToken
        ]
        if let nonce = nonce {
            body["nonce"] = nonce
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Authentication failed"
            throw SupabaseError.authError(message)
        }
        
        let sessionResponse = try JSONDecoder.supabase.decode(AuthSessionResponse.self, from: data)
        await handleAuthSession(sessionResponse)
    }
    
    // MARK: - Session Handling
    
    private func handleAuthSession(_ session: AuthSessionResponse) async {
        // Store tokens securely
        let storedSession = StoredSession(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(session.expiresIn)),
            userId: session.user.id
        )
        
        if let sessionData = try? JSONEncoder().encode(storedSession) {
            KeychainHelper.save(key: "supabase_session", data: sessionData)
        }
        
        // Update Supabase client
        await supabase.setSession(accessToken: session.accessToken, refreshToken: session.refreshToken)
        
        // Create profile if needed
        await createProfileIfNeeded(for: session.user)
        
        // Fetch full user data
        await fetchCurrentUser(userId: session.user.id)
    }
    
    private func createProfileIfNeeded(for authUser: AuthUser) async {
        do {
            // Check if profile exists
            let profiles: [Profile] = try await supabase.get(
                from: "profiles",
                filters: ["id": "eq.\(authUser.id.uuidString)"],
                limit: 1
            )
            
            if profiles.isEmpty {
                // Create new profile
                let newProfile = Profile.new(
                    id: authUser.id,
                    displayName: authUser.email?.components(separatedBy: "@").first ?? "User",
                    phoneNumber: authUser.phone
                )
                
                let _: [Profile] = try await supabase.insert(into: "profiles", values: newProfile)
            }
        } catch {
            print("Error creating profile: \(error)")
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() async {
        KeychainHelper.delete(key: "supabase_session")
        await supabase.clearSession()
        
        currentUser = nil
        authState = .unauthenticated
        authStateContinuation?.yield(nil)
    }
}

// MARK: - Apple Sign In Delegate

private class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    let continuation: CheckedContinuation<ASAuthorization, Error>
    
    init(continuation: CheckedContinuation<ASAuthorization, Error>) {
        self.continuation = continuation
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        continuation.resume(returning: authorization)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation.resume(throwing: error)
    }
}

// MARK: - Auth Response Models

struct AuthSessionResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let user: AuthUser
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case user
    }
}

struct AuthUser: Codable {
    let id: UUID
    let email: String?
    let phone: String?
}

struct StoredSession: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let userId: UUID
}
