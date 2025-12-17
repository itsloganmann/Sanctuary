//
//  HapticManager.swift
//  Sanctuary
//
//  Haptic feedback manager for tactile responses
//

import UIKit

/// Singleton manager for haptic feedback
@MainActor
final class HapticManager: @unchecked Sendable {
    
    // MARK: - Generators
    
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    // MARK: - Initialization
    
    init() {
        prepareGenerators()
    }
    
    /// Pre-warm haptic engines for faster response
    private func prepareGenerators() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        impactRigid.prepare()
        impactSoft.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }
    
    // MARK: - Impact Feedback
    
    func lightImpact() {
        impactLight.impactOccurred()
        impactLight.prepare()
    }
    
    func mediumImpact() {
        impactMedium.impactOccurred()
        impactMedium.prepare()
    }
    
    /// Heavy impact - Use for panic button press
    func heavyImpact() {
        impactHeavy.impactOccurred()
        impactHeavy.prepare()
    }
    
    func rigidImpact() {
        impactRigid.impactOccurred()
        impactRigid.prepare()
    }
    
    func softImpact() {
        impactSoft.impactOccurred()
        impactSoft.prepare()
    }
    
    /// Variable intensity impact (0.0 - 1.0)
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat = 1.0) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred(intensity: intensity)
    }
    
    // MARK: - Notification Feedback
    
    func success() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }
    
    func warning() {
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }
    
    func error() {
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }
    
    // MARK: - Selection Feedback
    
    func selection() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }
    
    // MARK: - Custom Patterns
    
    /// Panic button pattern - strong confirmation feedback
    func panicConfirmation() {
        Task {
            heavyImpact()
            try? await Task.sleep(for: .milliseconds(100))
            heavyImpact()
            try? await Task.sleep(for: .milliseconds(100))
            rigidImpact()
        }
    }
    
    /// Check-in confirmation - gentle positive feedback
    func checkInConfirmation() {
        Task {
            mediumImpact()
            try? await Task.sleep(for: .milliseconds(150))
            success()
        }
    }
    
    /// Card swipe feedback
    func cardSwipe(direction: CardSwipeDirection) {
        switch direction {
        case .left:
            softImpact()
        case .right:
            mediumImpact()
        }
    }
    
    /// Timer warning pulses
    func timerWarning() {
        Task {
            for _ in 0..<3 {
                warning()
                try? await Task.sleep(for: .milliseconds(300))
            }
        }
    }
}

/// Direction of card swipe for haptic feedback
enum CardSwipeDirection {
    case left
    case right
}
