//
//  WelcomeView.swift
//  Sanctuary
//
//  Mock authentication screen with MeshGradient background
//

import SwiftUI

struct WelcomeView: View {
    @Environment(AppState.self) private var appState
    @State private var displayName = ""
    @State private var showNameField = false
    
    var body: some View {
        ZStack {
            MeshGradient.safetyMesh(intensity: 0.4)
                .ignoresSafeArea()
            
            VStack(spacing: DesignTokens.spacingXLarge) {
                Spacer()
                
                // Logo
                VStack(spacing: DesignTokens.spacingMedium) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Color.safetyOrange)
                        .shadow(color: Color.safetyOrange.opacity(0.5), radius: 20)
                    
                    Text("Sanctuary")
                        .font(.displayLarge)
                        .foregroundStyle(.white)
                    
                    Text("Your safety, your boundaries")
                        .font(.bodyLarge)
                        .foregroundStyle(Color.textSecondary)
                }
                
                Spacer()
                
                if showNameField {
                    VStack(spacing: DesignTokens.spacingMedium) {
                        TextField("Your name", text: $displayName)
                            .font(.headlineMedium)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium)
                                    .stroke(Color.borderSubtle, lineWidth: 1)
                            )
                        
                        Button("Continue") {
                            let name = displayName.isEmpty ? "User" : displayName
                            withAnimation(.spring(response: 0.5)) {
                                appState.signIn(name: name)
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(displayName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal, DesignTokens.spacingLarge)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    VStack(spacing: DesignTokens.spacingMedium) {
                        Button {
                            withAnimation(.spring(response: 0.4)) {
                                showNameField = true
                            }
                        } label: {
                            HStack {
                                Image(systemName: "person.fill")
                                Text("Get Started")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        
                        Text("No account needed — this is a demo")
                            .font(.labelSmall)
                            .foregroundStyle(Color.textTertiary)
                    }
                    .padding(.horizontal, DesignTokens.spacingLarge)
                }
                
                Spacer().frame(height: DesignTokens.spacingXLarge)
            }
        }
    }
}
