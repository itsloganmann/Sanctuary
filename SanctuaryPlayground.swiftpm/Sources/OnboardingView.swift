//
//  OnboardingView.swift
//  Sanctuary
//
//  Three-page onboarding carousel introducing core concepts
//

import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var currentPage = 0
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "shield.fill",
            title: "Your Safety Net",
            description: "A hold-to-activate panic button that instantly shares your GPS location with trusted contacts. Accessible from the lock screen — no unlocking needed.",
            color: .safetyOrange
        ),
        OnboardingPage(
            icon: "heart.text.square.fill",
            title: "Communicate Boundaries",
            description: "Swipe through boundary cards with a partner to express consent on your terms. No awkwardness, no assumptions — just clarity.",
            color: .pink
        ),
        OnboardingPage(
            icon: "person.2.fill",
            title: "Trusted Contacts",
            description: "Designate the people who matter most. When you need help, they receive real-time GPS coordinates and a custom emergency message.",
            color: .statusSafe
        )
    ]
    
    var body: some View {
        ZStack {
            Color.sanctuaryBlack.ignoresSafeArea()
            
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        onboardingPageView(pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Custom page indicators
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.safetyOrange : Color.textTertiary)
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, DesignTokens.spacingLarge)
                
                // Continue / Get Started button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        withAnimation { appState.hasCompletedOnboarding = true }
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, DesignTokens.spacingLarge)
                .padding(.bottom, DesignTokens.spacingMedium)
                
                if currentPage < pages.count - 1 {
                    Button("Skip") {
                        withAnimation { appState.hasCompletedOnboarding = true }
                    }
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textTertiary)
                    .padding(.bottom, DesignTokens.spacingLarge)
                } else {
                    Spacer().frame(height: 48)
                }
            }
        }
    }
    
    @ViewBuilder
    private func onboardingPageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: DesignTokens.spacingXLarge) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.15))
                    .frame(width: 160, height: 160)
                
                Circle()
                    .fill(page.color.opacity(0.08))
                    .frame(width: 220, height: 220)
                
                Image(systemName: page.icon)
                    .font(.system(size: 72))
                    .foregroundStyle(page.color)
                    .shadow(color: page.color.opacity(0.4), radius: 20)
            }
            
            VStack(spacing: DesignTokens.spacingMedium) {
                Text(page.title)
                    .font(.displayLarge)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, DesignTokens.spacingLarge)
            
            Spacer()
            Spacer()
        }
    }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}
