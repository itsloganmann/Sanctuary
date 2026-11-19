//
//  Theme.swift
//  Sanctuary
//
//  Design system: Deep Dark Mode with Safety Orange accents
//  San Francisco Rounded typography, OLED-optimized palette
//

import SwiftUI

// MARK: - Color Palette

extension Color {
    static let sanctuaryBlack = Color(red: 0, green: 0, blue: 0)
    static let safetyOrange = Color(red: 1.0, green: 0.373, blue: 0.0)
    static let cardBackground = Color(white: 0.08)
    static let cardBackgroundLight = Color(white: 0.12)
    
    static let statusSafe = Color(red: 0.19, green: 0.82, blue: 0.35)
    static let statusWarning = Color(red: 1.0, green: 0.75, blue: 0.0)
    static let statusDanger = Color(red: 0.9, green: 0.2, blue: 0.2)
    
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.7)
    static let textTertiary = Color(white: 0.5)
    
    static let borderSubtle = Color(white: 0.2)
    static let borderActive = Color.safetyOrange.opacity(0.5)
}

// MARK: - Typography (San Francisco Rounded)

extension Font {
    static let displayLarge  = Font.system(size: 34, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 28, weight: .bold, design: .rounded)
    static let displaySmall  = Font.system(size: 22, weight: .semibold, design: .rounded)
    
    static let headlineLarge  = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let headlineMedium = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let headlineSmall  = Font.system(size: 15, weight: .semibold, design: .rounded)
    
    static let bodyLarge  = Font.system(size: 17, weight: .regular, design: .rounded)
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .rounded)
    static let bodySmall  = Font.system(size: 13, weight: .regular, design: .rounded)
    
    static let labelLarge  = Font.system(size: 14, weight: .medium, design: .rounded)
    static let labelMedium = Font.system(size: 12, weight: .medium, design: .rounded)
    static let labelSmall  = Font.system(size: 11, weight: .medium, design: .rounded)
}

// MARK: - Design Tokens

enum DesignTokens {
    static let cornerRadiusSmall:  CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge:  CGFloat = 16
    static let cornerRadiusXLarge: CGFloat = 24
    
    static let spacingXSmall: CGFloat = 4
    static let spacingSmall:  CGFloat = 8
    static let spacingMedium: CGFloat = 16
    static let spacingLarge:  CGFloat = 24
    static let spacingXLarge: CGFloat = 32
    
    static let buttonHeightSmall:  CGFloat = 36
    static let buttonHeightMedium: CGFloat = 48
    static let buttonHeightLarge:  CGFloat = 56
}

// MARK: - Gradients

extension LinearGradient {
    static let primaryGradient = LinearGradient(
        colors: [Color.safetyOrange, Color.safetyOrange.opacity(0.8)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let dangerGradient = LinearGradient(
        colors: [Color.statusDanger, Color.statusDanger.opacity(0.7)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let safeGradient = LinearGradient(
        colors: [Color.statusSafe, Color.statusSafe.opacity(0.7)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// MARK: - Mesh Gradient (iOS 18+)

extension MeshGradient {
    static func safetyMesh(intensity: Double = 0.5) -> MeshGradient {
        MeshGradient(
            width: 3, height: 3,
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
    
    static func panicMesh(pulse: Double = 0) -> MeshGradient {
        MeshGradient(
            width: 3, height: 3,
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

// MARK: - View Modifiers

extension View {
    func cardShadow() -> some View {
        shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    func glowShadow(color: Color = .safetyOrange) -> some View {
        shadow(color: color.opacity(0.4), radius: 12, x: 0, y: 0)
    }
    func sanctuaryCard(isHighlighted: Bool = false) -> some View {
        self
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

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    var isDestructive = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headlineMedium)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: DesignTokens.buttonHeightMedium)
            .background(isDestructive ? LinearGradient.dangerGradient : LinearGradient.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
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
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
