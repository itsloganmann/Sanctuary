//
//  SupabaseClientWrapper.swift
//  Sanctuary
//
//  Wrapper for Supabase client with async/await support
//

import Foundation

/// Configuration for Supabase connection
enum SupabaseConfig {
    /// Your Supabase project URL
    /// TODO: Replace with your actual Supabase URL
    static let projectURL = URL(string: "https://your-project.supabase.co")!
    
    /// Your Supabase anon/public key
    /// TODO: Replace with your actual anon key
    static let anonKey = "your-anon-key"
    
    /// App URL scheme for deep linking
    static let redirectURL = URL(string: "sanctuary://auth-callback")!
}

/// Thread-safe wrapper for Supabase client operations
/// Uses actor for Swift 6 concurrency safety
actor SupabaseClientWrapper {
    
    // MARK: - Properties
    
    private let projectURL: URL
    private let anonKey: String
    private var accessToken: String?
    private var refreshToken: String?
    
    // MARK: - Initialization
    
    init(
        projectURL: URL = SupabaseConfig.projectURL,
        anonKey: String = SupabaseConfig.anonKey
    ) {
        self.projectURL = projectURL
        self.anonKey = anonKey
    }
    
    // MARK: - Auth Token Management
    
    func setSession(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
    
    func clearSession() {
        self.accessToken = nil
        self.refreshToken = nil
    }
    
    // MARK: - API Requests
    
    /// Perform a GET request to the Supabase REST API
    func get<T: Decodable>(
        from table: String,
        select: String = "*",
        filters: [String: String] = [:],
        order: String? = nil,
        limit: Int? = nil
    ) async throws -> T {
        var urlComponents = URLComponents(url: projectURL.appendingPathComponent("rest/v1/\(table)"), resolvingAgainstBaseURL: false)!
        
        var queryItems = [URLQueryItem(name: "select", value: select)]
        for (key, value) in filters {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        if let order = order {
            queryItems.append(URLQueryItem(name: "order", value: order))
        }
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        urlComponents.queryItems = queryItems
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request = addHeaders(to: request)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        return try JSONDecoder.supabase.decode(T.self, from: data)
    }
    
    /// Perform a POST request (insert)
    func insert<T: Encodable, R: Decodable>(
        into table: String,
        values: T,
        returning: String = "representation"
    ) async throws -> R {
        let url = projectURL.appendingPathComponent("rest/v1/\(table)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request = addHeaders(to: request)
        request.setValue(returning, forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONEncoder.supabase.encode(values)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        return try JSONDecoder.supabase.decode(R.self, from: data)
    }
    
    /// Perform a PATCH request (update)
    func update<T: Encodable, R: Decodable>(
        table: String,
        values: T,
        filters: [String: String],
        returning: String = "representation"
    ) async throws -> R {
        var urlComponents = URLComponents(url: projectURL.appendingPathComponent("rest/v1/\(table)"), resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = filters.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "PATCH"
        request = addHeaders(to: request)
        request.setValue(returning, forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONEncoder.supabase.encode(values)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        return try JSONDecoder.supabase.decode(R.self, from: data)
    }
    
    /// Perform a DELETE request
    func delete(
        from table: String,
        filters: [String: String]
    ) async throws {
        var urlComponents = URLComponents(url: projectURL.appendingPathComponent("rest/v1/\(table)"), resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = filters.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "DELETE"
        request = addHeaders(to: request)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
    }
    
    /// Call an RPC function
    func rpc<T: Decodable>(
        _ function: String,
        params: [String: Any] = [:]
    ) async throws -> T {
        let url = projectURL.appendingPathComponent("rest/v1/rpc/\(function)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request = addHeaders(to: request)
        request.httpBody = try JSONSerialization.data(withJSONObject: params)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        
        return try JSONDecoder.supabase.decode(T.self, from: data)
    }
    
    // MARK: - Helpers
    
    private func addHeaders(to request: URLRequest) -> URLRequest {
        var request = request
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        
        if let accessToken = accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw SupabaseError.httpError(statusCode: httpResponse.statusCode, message: message)
        }
    }
}

// MARK: - Supabase Errors

enum SupabaseError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case decodingError(Error)
    case authError(String)
    case notAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode, let message):
            return "HTTP \(statusCode): \(message)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .authError(let message):
            return "Authentication error: \(message)"
        case .notAuthenticated:
            return "User is not authenticated"
        }
    }
}

// MARK: - JSON Coders

extension JSONDecoder {
    static let supabase: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try ISO8601 with fractional seconds
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            // Try ISO8601 without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(dateString)")
        }
        return decoder
    }()
}

extension JSONEncoder {
    static let supabase: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}
