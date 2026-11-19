//
//  ContentView.swift
//  Sanctuary
//
//  Root navigation: onboarding → auth → dashboard
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        Group {
            if !appState.hasCompletedOnboarding {
                OnboardingView()
            } else if appState.isAuthenticated {
                DashboardView()
            } else {
                WelcomeView()
            }
        }
        .animation(.smooth(duration: 0.5), value: appState.isAuthenticated)
        .animation(.smooth(duration: 0.5), value: appState.hasCompletedOnboarding)
    }
}
