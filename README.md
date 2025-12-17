# Sanctuary iOS App

> **Your safety, your boundaries** - A dual-purpose personal safety and consent application for iOS 18+

![iOS 18+](https://img.shields.io/badge/iOS-18%2B-blue)
![Swift 6](https://img.shields.io/badge/Swift-6-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-green)
![Supabase](https://img.shields.io/badge/Backend-Supabase-purple)

## 📱 Overview

Sanctuary is a mission-critical iOS application with two core features:

### 1. 🤝 Consent Manager
A non-legalistic, friction-free tool for couples to communicate boundaries. It replaces "contracts" with "agreements" through an intuitive card-swiping interface.

### 2. 🆘 Safety Widget  
A high-priority, lock-screen accessible panic button for emergency situations. Features include:
- **Dead Man's Switch**: Automatic alert if you don't check in
- **Live Location Broadcasting**: Real-time location sharing with trusted contacts
- **One-tap Panic**: Quick access from lock screen via widget

## 🏗 Architecture

```
Sanctuary/
├── App/                          # App entry point
│   ├── SanctuaryApp.swift       # @main entry
│   ├── DependencyContainer.swift # DI container
│   └── ContentView.swift         # Root view
├── Core/
│   ├── Models/                   # Data models (Codable, Sendable)
│   ├── Services/                 # Business logic
│   │   ├── AuthManager.swift     # Supabase Auth
│   │   ├── SafetyLocationManager.swift  # CoreLocation
│   │   ├── HapticManager.swift   # Haptic feedback
│   │   └── SupabaseClientWrapper.swift
│   ├── Repositories/             # Data access layer
│   ├── Intents/                  # App Intents for Widget
│   └── Utilities/                # Helpers
├── Features/
│   ├── Auth/                     # Authentication views
│   ├── Dashboard/                # Main BentoGrid view
│   ├── Consent/                  # Card stack, QR scanner
│   ├── Safety/                   # Panic mode UI
│   └── Settings/                 # Configuration
├── UI/
│   └── Theme/                    # Design system
├── SanctuaryWidget/              # WidgetKit extension
│   ├── SafetyWidget.swift        # Home/lock screen widget
│   └── SafetyLiveActivityView.swift  # Live Activity
└── Supabase/
    └── schema.sql                # Database schema
```

## 🎨 Design System

- **Theme**: Deep Dark Mode (OLED Black `#000000`)
- **Accent**: Safety Orange (`#FF5F00`)
- **Typography**: San Francisco Rounded
- **States**: 
  - Idle: Green Shield
  - Active: Pulsing Orange Radar
  - Panic: Red Alert

## 🚀 Getting Started

### Prerequisites

- Xcode 16.0+ (for iOS 18 SDK)
- iOS 18.0+ device (or simulator)
- Supabase account
- Apple Developer Account (for widgets and Sign in with Apple)

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/sanctuary-ios.git
cd sanctuary-ios
```

### 2. Set Up Supabase

1. Create a new Supabase project at [supabase.com](https://supabase.com)
2. Go to **SQL Editor** and run the contents of `Supabase/schema.sql`
3. Enable the following Auth providers:
   - Apple Sign-In
   - Phone (SMS)
4. Configure Realtime for `safety_alerts` and `location_updates` tables

### 3. Configure the App

Update `SupabaseClientWrapper.swift` with your credentials:

```swift
enum SupabaseConfig {
    static let projectURL = URL(string: "https://YOUR-PROJECT.supabase.co")!
    static let anonKey = "YOUR-ANON-KEY"
}
```

### 4. Configure Signing

1. Open the project in Xcode
2. Select your Development Team
3. Update Bundle Identifiers:
   - Main app: `com.yourcompany.sanctuary`
   - Widget: `com.yourcompany.sanctuary.widget`
4. Add App Group: `group.com.sanctuary.app` to both targets
5. Enable capabilities:
   - Background Modes (Location, Remote Notifications, Background Fetch)
   - Sign in with Apple
   - App Groups
   - Push Notifications

### 5. Build and Run

```bash
open Sanctuary.xcodeproj
# Or use Xcode GUI
```

## 📍 Background Location Strategy

The app uses multiple strategies to maintain location tracking during panic mode:

```
┌─────────────────────────────────────────────────────────────┐
│  Widget Tap → ToggleSafetyMonitoringIntent                  │
│       │                                                      │
│       ▼  (openAppWhenRun = true)                            │
│  App gets foreground time                                    │
│       │                                                      │
│       ├──► CLBackgroundActivitySession (iOS 17+)            │
│       │    Prevents app suspension                           │
│       │                                                      │
│       ├──► allowsBackgroundLocationUpdates = true           │
│       │    Enables background location                       │
│       │                                                      │
│       ├──► Live Activity Started                            │
│       │    Lock screen presence + quick actions              │
│       │                                                      │
│       └──► CLLocationUpdate.liveUpdates()                   │
│            Async stream for continuous tracking              │
└─────────────────────────────────────────────────────────────┘
```

## 🔒 Privacy & Security

- All location data is end-to-end encrypted
- Row-Level Security (RLS) ensures users can only access their own data
- Trusted contacts can view alerts via RLS policies
- Sessions stored in iOS Keychain
- No third-party analytics or tracking

## 📋 Database Schema

| Table | Description |
|-------|-------------|
| `profiles` | User profiles and settings |
| `contact_relations` | Trusted contact relationships |
| `agreements` | Consent agreements between partners |
| `safety_alerts` | Emergency alerts with location |
| `location_updates` | High-frequency location data |
| `linking_codes` | QR code linking for pairing |

## 🎯 Key Features

### Widget & Live Activity
- Interactive lock screen widget
- Dynamic Island support
- Check-in button without unlocking
- Panic escalation button

### Consent Cards
- Tinder-like swipe interface
- 8 default boundary categories
- Custom notes per boundary
- QR code pairing

### Safety Monitoring
- Hold-to-activate panic button
- Dead Man's Switch timer
- Real-time location broadcasting
- Automatic 911 escalation option

## 📱 Supported Devices

- iPhone with iOS 18.0+
- Dynamic Island devices recommended for best Live Activity experience

## 🛠 Development

### Code Style
- Swift 6 with strict concurrency
- `async/await` throughout (no completion handlers)
- `@Observable` for view models
- `actor` for thread-safe singletons
- All models: `Codable`, `Identifiable`, `Sendable`

### Running Tests

```bash
xcodebuild test -scheme Sanctuary -destination 'platform=iOS Simulator,name=iPhone 16'
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📞 Support

For support, email support@sanctuary.app or join our Discord community.

---

**Built with ❤️ for personal safety**
