# Sanctuary iOS App - Copilot Instructions

## Project Overview
Sanctuary is a dual-purpose iOS 18+ personal safety and consent application:
1. **Consent Manager**: Friction-free boundary communication tool for couples
2. **Safety Widget**: Lock-screen accessible panic button with Dead Man's Switch

## Technical Stack
- **Platform**: iOS 18+ (Swift 6)
- **UI**: SwiftUI with MeshGradient, modern transitions
- **Backend**: Supabase (Auth, Database, Realtime, Edge Functions)
- **Widgets**: WidgetKit + AppIntents (Interactive)
- **Location**: CoreLocation with CLServiceSession, CLBackgroundActivitySession
- **Architecture**: MVVM with centralized DependencyContainer

## Design System
- **Theme**: Deep Dark Mode (OLED Black #000000)
- **Accent**: Safety Orange (#FF5F00)
- **Typography**: San Francisco Rounded
- **States**: Idle (Green Shield) vs Active (Pulsing Orange Radar)

## Code Style Guidelines
- Use Swift 6 concurrency (async/await) throughout
- Avoid completion handlers - use modern async patterns
- All models must conform to `Codable`, `Identifiable`, `Sendable`
- Use `@Observable` macro for view models (iOS 17+)
- Prefer `actor` for thread-safe singletons
- Use structured concurrency with `TaskGroup` where appropriate

## Architecture Patterns
- MVVM with `DependencyContainer` for DI
- Singleton managers: `AuthManager`, `SafetyLocationManager`, `HapticManager`
- Repository pattern for Supabase data access
- Protocol-oriented design for testability

## File Organization
```
Sanctuary/
├── App/                    # App entry point, DependencyContainer
├── Core/
│   ├── Models/            # Data models matching Supabase schema
│   ├── Services/          # AuthManager, LocationManager, etc.
│   ├── Repositories/      # Supabase data access layer
│   └── Utilities/         # Extensions, helpers
├── Features/
│   ├── Safety/            # Safety monitoring, panic mode
│   ├── Consent/           # Agreement management, QR linking
│   └── Dashboard/         # Main BentoGrid view
├── UI/
│   ├── Components/        # Reusable UI components
│   ├── Theme/             # Colors, fonts, design tokens
│   └── Modifiers/         # Custom view modifiers
└── Widget/                # WidgetKit extension
```

## Key Implementation Notes
- Use `CLBackgroundActivitySession` for background location persistence
- Widget uses `LiveActivityIntent` with `openAppWhenRun = true` for foreground time
- Haptic feedback: Heavy impact on panic button press
- Live Activity shows monitoring status on lock screen

## Supabase Configuration
- Enable Realtime for `safety_alerts` table
- RLS: Users access own data; trusted contacts can read safety_alerts
- Auth providers: Apple Sign-In, Phone/SMS
