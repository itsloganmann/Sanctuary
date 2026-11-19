# Sanctuary

[![iOS 18+](https://img.shields.io/badge/iOS-18%2B-blue)](https://developer.apple.com/ios/)
[![Swift 6](https://img.shields.io/badge/Swift-6-orange)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-green)](https://developer.apple.com/xcode/swiftui/)
[![Supabase](https://img.shields.io/badge/Backend-Supabase-3ECF8E)](https://supabase.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A dual-purpose personal safety and consent management iOS application. Sanctuary provides a lock-screen accessible panic button with real-time GPS alerting and a frictionless consent agreement system for partners.

**Live Demo:** [sanctuary-ios-safety.vercel.app](https://sanctuary-ios-safety.vercel.app)

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Design System](#design-system)
- [Getting Started](#getting-started)
- [Background Location Architecture](#background-location-architecture)
- [Privacy and Security](#privacy-and-security)
- [Database Schema](#database-schema)
- [Key Features](#key-features)
- [Supported Devices](#supported-devices)
- [Development Standards](#development-standards)
- [Contributing](#contributing)
- [License](#license)
- [Support](#support)

---

## Overview

Sanctuary addresses two distinct personal safety needs in a single, production-grade iOS application:

**Safety Monitoring**

An emergency response system featuring a hold-to-activate panic button, a configurable Dead Man's Switch timer, and real-time GPS location broadcasting to designated trusted contacts. All safety features are accessible directly from the iOS lock screen via a WidgetKit extension with Dynamic Island support.

**Consent Management**

A non-legalistic communication tool for partners to express, document, and review personal boundaries across eight configurable categories. Partners link accounts via QR code and interact through a card-swipe interface.

---

## Architecture

```
Sanctuary/
  App/
    SanctuaryApp.swift              Entry point
    DependencyContainer.swift       Centralized dependency injection
    ContentView.swift               Root navigation view
  Core/
    Models/                         Codable, Sendable data models
    Services/
      AuthManager.swift             Supabase authentication
      SafetyLocationManager.swift   CoreLocation, background sessions
      HapticManager.swift           Haptic feedback patterns
      SupabaseClientWrapper.swift   API client configuration
    Repositories/                   Data access layer (repository pattern)
    Intents/                        App Intents for WidgetKit interactivity
    Utilities/                      Extensions and helpers
  Features/
    Auth/                           Phone and email authentication
    Dashboard/                      Main BentoGrid dashboard
    Consent/                        Card stack and QR code scanner
    Safety/                         Panic mode UI
    Settings/                       User configuration
  UI/
    Theme/                          Design tokens, colors, typography
SanctuaryWidget/
  SafetyWidget.swift                Lock screen and home screen widget
  SafetyLiveActivityView.swift      Dynamic Island and Live Activity
Supabase/
  schema.sql                        PostgreSQL schema with RLS policies
```

**Design Pattern:** MVVM with a centralized `DependencyContainer` for dependency injection. All services use the `@Observable` macro. Thread-safe singletons use Swift `actor` isolation.

---

## Design System

| Token | Value |
|-------|-------|
| Background | OLED Black `#000000` |
| Accent | Safety Orange `#FF5F00` |
| Safe State | Green `#30D158` |
| Danger State | Red `#FF3B30` |
| Typography | San Francisco Rounded |

---

## Getting Started

### Prerequisites

- Xcode 16.0 or later (iOS 18 SDK required)
- iOS 18.0 device or simulator
- Supabase account
- Apple Developer Account (required for WidgetKit, App Groups, and Sign in with Apple)

### 1. Clone the Repository

```bash
git clone https://github.com/itsloganmann/Sanctuary.git
cd Sanctuary
```

### 2. Set Up Supabase

1. Create a new project at [supabase.com](https://supabase.com).
2. Open the SQL Editor and execute the contents of `Supabase/schema.sql`.
3. Enable the following Auth providers: Phone (SMS) and Apple Sign-In.
4. Enable Realtime for the `safety_alerts` and `location_updates` tables.
5. Configure Twilio credentials in the Supabase Auth settings for SMS delivery.

### 3. Configure the App

Update `Sanctuary/Core/Services/SupabaseClientWrapper.swift` with your project credentials:

```swift
enum SupabaseConfig {
    static let projectURL = URL(string: "https://YOUR-PROJECT.supabase.co")!
    static let anonKey = "YOUR-ANON-KEY"
}
```

### 4. Configure Xcode Signing

1. Open the project in Xcode.
2. Select your Apple Developer Team for both the `Sanctuary` and `SanctuaryWidget` targets.
3. Set bundle identifiers:
   - Main app: `com.yourcompany.sanctuary`
   - Widget: `com.yourcompany.sanctuary.widget`
4. Add the App Group `group.com.sanctuary.app` to both targets.
5. Enable the following capabilities: Background Modes (Location updates, Remote notifications, Background fetch), Sign in with Apple, App Groups, Push Notifications.

### 5. Build and Run

```bash
open Sanctuary.xcodeproj
```

Or build from the command line:

```bash
xcodebuild -scheme Sanctuary -destination 'platform=iOS Simulator,name=iPhone 16' build
```

---

## Background Location Architecture

Sanctuary uses a layered approach to maintain continuous location tracking during active safety sessions:

```
Widget Tap -> ToggleSafetyMonitoringIntent (openAppWhenRun = true)
     |
     +-- CLBackgroundActivitySession    Prevents app suspension
     |
     +-- allowsBackgroundLocationUpdates = true
     |
     +-- Live Activity started          Lock screen presence
     |
     +-- CLLocationUpdate.liveUpdates() Async stream, continuous GPS
```

This pattern ensures location updates continue when the device is locked, the app is backgrounded, or the user has not interacted with the app for an extended period.

---

## Privacy and Security

- Row-Level Security (RLS) policies enforce per-user data isolation at the database level.
- Trusted contacts can read only the `safety_alerts` records designated for them.
- Authentication sessions are persisted in the iOS Keychain.
- All API traffic uses HTTPS/TLS.
- No third-party analytics SDKs are included.
- Location data is retained only for the duration of an active safety session.

**Privacy Policy:** [sanctuary-ios-safety.vercel.app/privacy-policy.html](https://sanctuary-ios-safety.vercel.app/privacy-policy.html)

**Terms and Conditions:** [sanctuary-ios-safety.vercel.app/terms.html](https://sanctuary-ios-safety.vercel.app/terms.html)

---

## Database Schema

| Table | Description |
|-------|-------------|
| `profiles` | User profiles and notification settings |
| `contact_relations` | Trusted contact relationships |
| `agreements` | Consent agreements between linked partners |
| `safety_alerts` | Emergency alerts with GPS coordinates |
| `location_updates` | High-frequency location telemetry |
| `linking_codes` | Temporary QR code pairing tokens |

---

## Key Features

### Lock Screen Widget

- Interactive WidgetKit extension supporting check-in and panic activation without unlocking the device
- Dynamic Island Live Activity shows active monitoring status and elapsed time

### Consent Card Interface

- Swipe-to-accept interface across eight boundary categories
- Custom notes per agreement
- QR code partner linking

### Panic and Safety Monitoring

- Hold-to-activate panic button (1.5-second threshold prevents accidental triggers)
- Dead Man's Switch with configurable intervals (15 minutes to 24 hours)
- Automatic SMS dispatch to trusted contacts via Twilio A2P 10DLC-compliant messaging

---

## Supported Devices

- iPhone running iOS 18.0 or later
- Dynamic Island-equipped devices (iPhone 14 Pro and later) provide the optimal Live Activity experience

---

## Development Standards

- Swift 6 strict concurrency throughout
- `async/await` for all asynchronous operations (no completion handler callbacks)
- `@Observable` macro for all view models (iOS 17+)
- `actor` for all shared mutable state
- All models conform to `Codable`, `Identifiable`, and `Sendable`

### Running Tests

```bash
xcodebuild test -scheme Sanctuary -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## Contributing

1. Fork the repository.
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Commit your changes: `git commit -m 'Add feature description'`
4. Push the branch: `git push origin feature/your-feature-name`
5. Open a pull request.

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

## Support

Email: support@sanctuary.app
