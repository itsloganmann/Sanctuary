//
//  SafetyLocationManager.swift
//  Sanctuary
//
//  Critical component: CoreLocation manager with background persistence and panic mode
//
//  BACKGROUND LOCATION STRATEGY:
//  ================================
//  iOS aggressively suspends apps in the background. To maintain continuous location
//  tracking during panic mode, we employ multiple legal strategies:
//
//  1. CLBackgroundActivitySession (iOS 17+):
//     - Keeps the app running in background while session is active
//     - Must be started while app is in foreground
//     - Persists across lock screen events
//
//  2. allowsBackgroundLocationUpdates = true:
//     - Required for any background location updates
//     - Must be enabled BEFORE entering background
//
//  3. Live Activity (WidgetKit):
//     - Provides additional foreground time via openAppWhenRun
//     - Acts as visual indicator on lock screen
//     - User can interact without unlocking phone
//
//  4. Info.plist Configuration:
//     - UIBackgroundModes: location, remote-notification
//     - NSLocationAlwaysAndWhenInUseUsageDescription
//     - NSLocationWhenInUseUsageDescription
//

import Foundation
import CoreLocation
import Observation
import UIKit

/// Location authorization status wrapper
enum LocationAuthStatus: Sendable {
    case notDetermined
    case denied
    case authorizedWhenInUse
    case authorizedAlways
    
    var canMonitorInBackground: Bool {
        self == .authorizedAlways
    }
    
    var displayMessage: String {
        switch self {
        case .notDetermined:
            return "Location permission required for safety monitoring"
        case .denied:
            return "Location access denied. Enable in Settings for safety features."
        case .authorizedWhenInUse:
            return "Upgrade to 'Always' for background monitoring"
        case .authorizedAlways:
            return "Full location access enabled"
        }
    }
}

/// Monitoring intensity level
enum MonitoringLevel: Sendable {
    case off
    case checkIn      // Low power, periodic updates
    case active       // Medium accuracy, regular updates
    case panic        // High accuracy, continuous updates
    
    var desiredAccuracy: CLLocationAccuracy {
        switch self {
        case .off: return kCLLocationAccuracyReduced
        case .checkIn: return kCLLocationAccuracyHundredMeters
        case .active: return kCLLocationAccuracyNearestTenMeters
        case .panic: return kCLLocationAccuracyBest
        }
    }
    
    var distanceFilter: CLLocationDistance {
        switch self {
        case .off: return CLLocationDistanceMax
        case .checkIn: return 100 // meters
        case .active: return 20
        case .panic: return 5
        }
    }
    
    var activityType: CLActivityType {
        switch self {
        case .off, .checkIn: return .other
        case .active, .panic: return .fitness // Best for walking/running
        }
    }
}

/// Main location manager for safety features
/// Uses @Observable for SwiftUI integration
@Observable
@MainActor
final class SafetyLocationManager: NSObject {
    
    // MARK: - Published Properties
    
    var authorizationStatus: LocationAuthStatus = .notDetermined
    var currentLocation: CLLocation?
    var monitoringLevel: MonitoringLevel = .off
    var isPanicModeActive: Bool = false
    var lastError: String?
    
    /// Location history during active monitoring
    var locationHistory: [CLLocation] = []
    
    // MARK: - Private Properties
    
    private let locationManager: CLLocationManager
    private var backgroundSession: CLBackgroundActivitySession?
    private var locationUpdateTask: Task<Void, Never>?
    
    /// Continuation for async location stream
    private var locationContinuation: AsyncStream<CLLocation>.Continuation?

    // MARK: - Alert Sending

    /// Send alert to trusted contacts via Supabase Edge Function
    func sendAlertToContacts(location: CLLocation, message: String) async {
        guard let userId = DependencyContainer.shared.authManager.currentUser?.id else { return }
        guard let url = URL(string: "https://kpuichvxsgsisnnzexib.functions.supabase.co/send_alert") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "user_id": userId.uuidString,
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "message": message
        ]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Failed to send alert to contacts")
                return
            }
            print("Alert sent to contacts!")
        } catch {
            print("Error sending alert: \(error)")
        }
    }
    
    // MARK: - Initialization
    
    override init() {
        self.locationManager = CLLocationManager()
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
        
        updateAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    /// Request location authorization
    func requestAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            // Upgrade to Always for background monitoring
            locationManager.requestAlwaysAuthorization()
        default:
            break
        }
    }
    
    /// Request Always authorization (required for background monitoring)
    func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }
    
    private func updateAuthorizationStatus() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            authorizationStatus = .notDetermined
        case .denied, .restricted:
            authorizationStatus = .denied
        case .authorizedWhenInUse:
            authorizationStatus = .authorizedWhenInUse
        case .authorizedAlways:
            authorizationStatus = .authorizedAlways
        @unknown default:
            authorizationStatus = .denied
        }
    }
    
    // MARK: - Panic Mode
    
    /// Start panic mode with maximum location tracking
    ///
    /// CRITICAL: This function must be called while app is in foreground.
    /// The CLBackgroundActivitySession can only be created in foreground.
    func startPanicMode() async throws {
        guard authorizationStatus.canMonitorInBackground else {
            throw LocationError.insufficientPermissions
        }
        
        isPanicModeActive = true
        monitoringLevel = .panic
        locationHistory.removeAll()
        
        // Configure for high-accuracy continuous tracking
        locationManager.desiredAccuracy = MonitoringLevel.panic.desiredAccuracy
        locationManager.distanceFilter = MonitoringLevel.panic.distanceFilter
        locationManager.activityType = MonitoringLevel.panic.activityType
        
        // CRITICAL: Enable background updates BEFORE going to background
        // Check if the app has "location" in UIBackgroundModes
        let hasBackgroundLocation: Bool = {
            guard let modes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] else {
                return false
            }
            return modes.contains("location")
        }()
        
        if hasBackgroundLocation {
            locationManager.allowsBackgroundLocationUpdates = true
            // Start background activity session (iOS 17+)
            // This is the key to keeping the app alive in background
            backgroundSession = CLBackgroundActivitySession()
        } else {
            // Log warning - background location not configured
            print("⚠️ WARNING: UIBackgroundModes does not contain 'location'. Background tracking disabled.")
        }
        
        // Start location updates using modern async stream (iOS 17+)
        await startLocationStream()
        
        // Also start legacy updates as fallback
        locationManager.startUpdatingLocation()

        // Send alert to trusted contacts
        if let location = currentLocation {
            await sendAlertToContacts(location: location, message: "I need help. This is an emergency.")
        }
    }
    
    /// Stop panic mode and release resources
    func stopPanicMode() async {
        isPanicModeActive = false
        monitoringLevel = .off
        
        // Stop location updates
        locationUpdateTask?.cancel()
        locationUpdateTask = nil
        locationContinuation?.finish()
        locationContinuation = nil
        
        // Stop legacy updates
        locationManager.stopUpdatingLocation()
        
        // Release background session
        // Setting to nil ends the session
        backgroundSession?.invalidate()
        backgroundSession = nil
        
        // Disable background mode
        locationManager.allowsBackgroundLocationUpdates = false
    }
    
    // MARK: - Check-In Mode (Lower Power)
    
    func startCheckInMonitoring(intervalMinutes: Int) async {
        monitoringLevel = .checkIn
        
        locationManager.desiredAccuracy = MonitoringLevel.checkIn.desiredAccuracy
        locationManager.distanceFilter = MonitoringLevel.checkIn.distanceFilter
        
        // For check-in mode, we use significant location changes
        // This is more battery efficient
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    func stopCheckInMonitoring() {
        monitoringLevel = .off
        locationManager.stopMonitoringSignificantLocationChanges()
    }
    
    // MARK: - Modern Location Stream (iOS 17+)
    
    /// Start continuous location updates using CLLocationUpdate.liveUpdates()
    private func startLocationStream() async {
        locationUpdateTask?.cancel()
        
        locationUpdateTask = Task {
            // Use the new iOS 17 async sequence for location updates
            do {
                let updates = CLLocationUpdate.liveUpdates(.automotiveNavigation)
                
                for try await update in updates {
                    guard !Task.isCancelled else { break }
                    
                    if let location = update.location {
                        await processLocationUpdate(location)
                    }
                    
                    // Check if we're still in panic mode
                    if !isPanicModeActive {
                        break
                    }
                }
            } catch {
                lastError = "Location updates failed: \(error.localizedDescription)"
            }
        }
    }
    
    /// Process incoming location update
    private func processLocationUpdate(_ location: CLLocation) async {
        currentLocation = location
        locationHistory.append(location)
        
        // Limit history to last 1000 points (prevent memory issues)
        if locationHistory.count > 1000 {
            locationHistory.removeFirst(100)
        }
        
        // Notify observers via continuation
        locationContinuation?.yield(location)
    }
    
    // MARK: - Async Stream for External Subscribers
    
    /// Provides an async stream of location updates for external subscribers
    var locationStream: AsyncStream<CLLocation> {
        AsyncStream { continuation in
            self.locationContinuation = continuation
            
            continuation.onTermination = { _ in
                // Cleanup if needed
            }
        }
    }
    
    // MARK: - Utility Methods
    
    /// Get current battery level
    func getBatteryLevel() -> Double? {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        return level >= 0 ? Double(level) : nil
    }
    
    /// Check if location services are enabled
    var isLocationServicesEnabled: Bool {
        CLLocationManager.locationServicesEnabled()
    }
}

// MARK: - CLLocationManagerDelegate

extension SafetyLocationManager: CLLocationManagerDelegate {
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            updateAuthorizationStatus()
            
            // Auto-start panic mode if we just got Always authorization while waiting
            if authorizationStatus == .authorizedAlways && isPanicModeActive {
                // Re-establish background session
                backgroundSession = CLBackgroundActivitySession()
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            for location in locations {
                await processLocationUpdate(location)
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            lastError = error.localizedDescription
            
            // Don't stop panic mode on transient errors
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    authorizationStatus = .denied
                case .network:
                    // Transient, will retry
                    break
                default:
                    break
                }
            }
        }
    }
}

// MARK: - Location Errors

enum LocationError: LocalizedError {
    case insufficientPermissions
    case locationServicesDisabled
    case panicModeAlreadyActive
    
    var errorDescription: String? {
        switch self {
        case .insufficientPermissions:
            return "Always location permission is required for panic mode"
        case .locationServicesDisabled:
            return "Location services are disabled on this device"
        case .panicModeAlreadyActive:
            return "Panic mode is already active"
        }
    }
}
