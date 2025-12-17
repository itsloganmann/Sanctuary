//
//  ConsentSelectionView.swift
//  Sanctuary
//
//  Tinder-style card stack for selecting consent boundaries
//

import SwiftUI

struct ConsentSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DependencyContainer.self) private var dependencies
    
    @State private var boundaries: [BoundaryCard] = BoundaryCard.defaultCards
    @State private var currentIndex = 0
    @State private var showingReview = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.sanctuaryBlack
                    .ignoresSafeArea()
                
                VStack(spacing: DesignTokens.spacingLarge) {
                    // Progress indicator
                    ProgressView(value: Double(currentIndex), total: Double(boundaries.count))
                        .tint(.safetyOrange)
                        .padding(.horizontal)
                    
                    // Instructions
                    VStack(spacing: DesignTokens.spacingSmall) {
                        Text("Set Your Boundaries")
                            .font(.displaySmall)
                            .foregroundStyle(.white)
                        
                        Text("Swipe right to consent, left to decline")
                            .font(.bodyMedium)
                            .foregroundStyle(.textSecondary)
                    }
                    
                    // Card Stack
                    ZStack {
                        ForEach(boundaries.indices.reversed(), id: \.self) { index in
                            if index >= currentIndex && index < currentIndex + 3 {
                                ConsentCard(
                                    card: boundaries[index],
                                    isTop: index == currentIndex
                                ) { direction in
                                    handleSwipe(at: index, direction: direction)
                                }
                                .offset(y: CGFloat(index - currentIndex) * 8)
                                .scaleEffect(1 - CGFloat(index - currentIndex) * 0.05)
                                .zIndex(Double(boundaries.count - index))
                            }
                        }
                        
                        if currentIndex >= boundaries.count {
                            // All done
                            VStack(spacing: DesignTokens.spacingMedium) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.statusSafe)
                                
                                Text("All Set!")
                                    .font(.displaySmall)
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .frame(height: 400)
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Action buttons
                    HStack(spacing: DesignTokens.spacingXLarge) {
                        // Decline button
                        Button {
                            if currentIndex < boundaries.count {
                                handleSwipe(at: currentIndex, direction: .left)
                            }
                        } label: {
                            Circle()
                                .fill(Color.statusDanger.opacity(0.2))
                                .frame(width: 64, height: 64)
                                .overlay(
                                    Image(systemName: "xmark")
                                        .font(.title2.bold())
                                        .foregroundStyle(.statusDanger)
                                )
                        }
                        
                        // Accept button
                        Button {
                            if currentIndex < boundaries.count {
                                handleSwipe(at: currentIndex, direction: .right)
                            }
                        } label: {
                            Circle()
                                .fill(Color.statusSafe.opacity(0.2))
                                .frame(width: 64, height: 64)
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.title2.bold())
                                        .foregroundStyle(.statusSafe)
                                )
                        }
                    }
                    .padding(.bottom, DesignTokens.spacingLarge)
                }
            }
            .navigationTitle("Boundaries")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.textSecondary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Review") {
                        showingReview = true
                    }
                    .foregroundStyle(.safetyOrange)
                }
            }
            .sheet(isPresented: $showingReview) {
                BoundaryReviewView(boundaries: boundaries)
            }
        }
    }
    
    private func handleSwipe(at index: Int, direction: SwipeDirection) {
        guard index < boundaries.count else { return }
        
        dependencies.hapticManager.cardSwipe(direction: direction == .right ? .right : .left)
        
        boundaries[index].consent = (direction == .right)
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentIndex += 1
        }
    }
}

// MARK: - Swipe Direction

enum SwipeDirection {
    case left, right
}

// MARK: - Boundary Card Model

struct BoundaryCard: Identifiable {
    let id = UUID()
    let category: String
    let description: String
    let icon: String
    let color: Color
    var consent: Bool = false
    
    static let defaultCards: [BoundaryCard] = [
        BoundaryCard(
            category: "Photos & Videos",
            description: "Allow taking and sharing photos or videos together",
            icon: "camera.fill",
            color: .purple
        ),
        BoundaryCard(
            category: "Staying Overnight",
            description: "Comfortable staying at each other's place",
            icon: "moon.stars.fill",
            color: .indigo
        ),
        BoundaryCard(
            category: "Physical Intimacy",
            description: "Comfortable with physical affection",
            icon: "heart.fill",
            color: .pink
        ),
        BoundaryCard(
            category: "Sharing Location",
            description: "Share real-time location with each other",
            icon: "location.fill",
            color: .safetyOrange
        ),
        BoundaryCard(
            category: "Meeting Friends",
            description: "Introduce each other to friend groups",
            icon: "person.3.fill",
            color: .blue
        ),
        BoundaryCard(
            category: "Social Media Posts",
            description: "Post about relationship on social media",
            icon: "bubble.left.and.bubble.right.fill",
            color: .cyan
        ),
        BoundaryCard(
            category: "Alcohol Together",
            description: "Comfortable drinking alcohol together",
            icon: "wineglass.fill",
            color: .red
        ),
        BoundaryCard(
            category: "Private Space",
            description: "Respect for personal time and space",
            icon: "house.fill",
            color: .green
        )
    ]
}

// MARK: - Consent Card View

struct ConsentCard: View {
    let card: BoundaryCard
    let isTop: Bool
    let onSwipe: (SwipeDirection) -> Void
    
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    
    private let swipeThreshold: CGFloat = 100
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusXLarge)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusXLarge)
                        .stroke(strokeColor, lineWidth: 2)
                )
            
            // Content
            VStack(spacing: DesignTokens.spacingLarge) {
                // Icon
                ZStack {
                    Circle()
                        .fill(card.color.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: card.icon)
                        .font(.system(size: 44))
                        .foregroundStyle(card.color)
                }
                
                // Text
                VStack(spacing: DesignTokens.spacingSmall) {
                    Text(card.category)
                        .font(.displaySmall)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(card.description)
                        .font(.bodyMedium)
                        .foregroundStyle(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
                .padding(.horizontal)
                
                // Swipe indicators
                HStack {
                    // Decline indicator
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.statusDanger)
                        .opacity(offset.width < -30 ? Double(-offset.width - 30) / 70 : 0)
                    
                    Spacer()
                    
                    // Accept indicator
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.statusSafe)
                        .opacity(offset.width > 30 ? Double(offset.width - 30) / 70 : 0)
                }
                .padding(.horizontal, DesignTokens.spacingLarge)
            }
            .padding(DesignTokens.spacingLarge)
        }
        .frame(width: 320, height: 380)
        .offset(offset)
        .rotationEffect(.degrees(rotation))
        .gesture(
            isTop ? DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation
                    rotation = Double(gesture.translation.width / 20)
                }
                .onEnded { gesture in
                    if gesture.translation.width > swipeThreshold {
                        // Swipe right
                        withAnimation(.easeOut(duration: 0.3)) {
                            offset = CGSize(width: 500, height: 0)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onSwipe(.right)
                        }
                    } else if gesture.translation.width < -swipeThreshold {
                        // Swipe left
                        withAnimation(.easeOut(duration: 0.3)) {
                            offset = CGSize(width: -500, height: 0)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onSwipe(.left)
                        }
                    } else {
                        // Return to center
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            offset = .zero
                            rotation = 0
                        }
                    }
                }
            : nil
        )
    }
    
    private var strokeColor: Color {
        if offset.width > 30 {
            return .statusSafe
        } else if offset.width < -30 {
            return .statusDanger
        } else {
            return .borderSubtle
        }
    }
}

// MARK: - Boundary Review View

struct BoundaryReviewView: View {
    @Environment(\.dismiss) private var dismiss
    let boundaries: [BoundaryCard]
    
    var body: some View {
        NavigationStack {
            List {
                Section("Consented") {
                    ForEach(boundaries.filter { $0.consent }) { card in
                        HStack {
                            Image(systemName: card.icon)
                                .foregroundStyle(card.color)
                            Text(card.category)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.statusSafe)
                        }
                    }
                }
                
                Section("Declined") {
                    ForEach(boundaries.filter { !$0.consent }) { card in
                        HStack {
                            Image(systemName: card.icon)
                                .foregroundStyle(card.color)
                            Text(card.category)
                            Spacer()
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.statusDanger)
                        }
                    }
                }
            }
            .navigationTitle("Review Boundaries")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ConsentSelectionView()
        .environment(DependencyContainer.shared)
}
