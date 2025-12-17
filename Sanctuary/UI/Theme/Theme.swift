//
//  Theme.swift
//  Sanctuary
//
//  Design system: Deep Dark Mode with Safety Orange accents
//

import SwiftUI

// MARK: - Color Palette

extension Color {
    /// Deep OLED Black for backgrounds
    static let sanctuaryBlack = Color(red: 0, green: 0, blue: 0) // #000000
    
    /// Primary accent - Safety Orange
    static let safetyOrange = Color(red: 1.0, green: 0.373, blue: 0.0) // #FF5F00
    
    /// Secondary backgrounds
    static let cardBackground = Color(white: 0.08)
    static let cardBackgroundLight = Color(white: 0.12)
    
    /// Status colors
    static let statusSafe = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let statusWarning = Color(red: 1.0, green: 0.75, blue: 0.0)
    static let statusDanger = Color(red: 0.9, green: 0.2, blue: 0.2)
    
    /// Text colors
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.7)
    static let textTertiary = Color(white: 0.5)
    
    /// Border colors
    static let borderSubtle = Color(white: 0.2)
    static let borderActive = Color.safetyOrange.opacity(0.5)
}

// MARK: - Typography

extension Font {
    /// Display - Large titles
    static let displayLarge = Font.system(size: 34, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 28, weight: .bold, design: .rounded)
    static let displaySmall = Font.system(size: 22, weight: .semibold, design: .rounded)
    
    /// Headlines
    static let headlineLarge = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let headlineMedium = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let headlineSmall = Font.system(size: 15, weight: .semibold, design: .rounded)
    
    /// Body text
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .rounded)
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .rounded)
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .rounded)
    
    /// Labels/Captions
    static let labelLarge = Font.system(size: 14, weight: .medium, design: .rounded)
    static let labelMedium = Font.system(size: 12, weight: .medium, design: .rounded)
    static let labelSmall = Font.system(size: 11, weight: .medium, design: .rounded)
}

// MARK: - Gradients

extension LinearGradient {
    /// Primary gradient for buttons
    static let primaryGradient = LinearGradient(
        colors: [Color.safetyOrange, Color.safetyOrange.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Danger gradient for panic elements
    static let dangerGradient = LinearGradient(
        colors: [Color.statusDanger, Color.statusDanger.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Safe gradient
    static let safeGradient = LinearGradient(
        colors: [Color.statusSafe, Color.statusSafe.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Card gradient
    static let cardGradient = LinearGradient(
        colors: [Color.cardBackground, Color.cardBackgroundLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Mesh Gradient (iOS 18+)

extension MeshGradient {
    /// Dynamic safety mesh gradient
    static func safetyMesh(intensity: Double = 0.5) -> MeshGradient {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                .sanctuaryBlack, .sanctuaryBlack, .sanctuaryBlack,
                .sanctuaryBlack, Color.safetyOrange.opacity(intensity * 0.3), .sanctuaryBlack,
                .sanctuaryBlack, .sanctuaryBlack, .sanctuaryBlack
            ]
        )
    }
    
    /// Panic mode mesh gradient
    static func panicMesh(pulse: Double = 0) -> MeshGradient {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                Color.statusDanger.opacity(0.3 + pulse * 0.2), .sanctuaryBlack, Color.statusDanger.opacity(0.2 + pulse * 0.1),
                .sanctuaryBlack, Color.statusDanger.opacity(0.4 + pulse * 0.3), .sanctuaryBlack,
                Color.statusDanger.opacity(0.2 + pulse * 0.1), .sanctuaryBlack, Color.statusDanger.opacity(0.3 + pulse * 0.2)
            ]
        )
    }
}

// MARK: - Design Tokens

enum DesignTokens {
    /// Corner radii
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16
    static let cornerRadiusXLarge: CGFloat = 24
    
    /// Spacing
    static let spacingXSmall: CGFloat = 4
    static let spacingSmall: CGFloat = 8
    static let spacingMedium: CGFloat = 16
    static let spacingLarge: CGFloat = 24
    static let spacingXLarge: CGFloat = 32
    
    /// Icon sizes
    static let iconSmall: CGFloat = 16
    static let iconMedium: CGFloat = 24
    static let iconLarge: CGFloat = 32
    static let iconXLarge: CGFloat = 48
    
    /// Button heights
    static let buttonHeightSmall: CGFloat = 36
    static let buttonHeightMedium: CGFloat = 48
    static let buttonHeightLarge: CGFloat = 56
    
    /// Animation durations
    static let animationFast: Double = 0.15
    static let animationMedium: Double = 0.3
    static let animationSlow: Double = 0.5
}

// MARK: - Shadow Styles

extension View {
    func cardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    func glowShadow(color: Color = .safetyOrange) -> some View {
        self.shadow(color: color.opacity(0.4), radius: 12, x: 0, y: 0)
    }
    
    func subtleShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    var isDestructive: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headlineMedium)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: DesignTokens.buttonHeightMedium)
            .background(
                isDestructive ? LinearGradient.dangerGradient : LinearGradient.primaryGradient
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: DesignTokens.animationFast), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headlineMedium)
            .foregroundStyle(Color.safetyOrange)
            .frame(maxWidth: .infinity)
            .frame(height: DesignTokens.buttonHeightMedium)
            .background(Color.safetyOrange.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium)
                    .stroke(Color.safetyOrange.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: DesignTokens.animationFast), value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headlineSmall)
            .foregroundStyle(Color.textSecondary)
            .padding(.horizontal, DesignTokens.spacingMedium)
            .padding(.vertical, DesignTokens.spacingSmall)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
    }
}

// MARK: - Card Style

struct CardModifier: ViewModifier {
    var isHighlighted: Bool = false
    
    func body(content: Content) -> some View {
        content
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusLarge)
                    .stroke(
                        isHighlighted ? Color.borderActive : Color.borderSubtle,
                        lineWidth: isHighlighted ? 2 : 1
                    )
            )
            .cardShadow()
    }
}

extension View {
    func sanctuaryCard(isHighlighted: Bool = false) -> some View {
        self.modifier(CardModifier(isHighlighted: isHighlighted))
    }
}
