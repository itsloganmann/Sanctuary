//
//  AuthenticationView.swift
//  Sanctuary
//
//  Authentication screen with Apple Sign-In and Phone auth
//

import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @Environment(DependencyContainer.self) private var dependencies
    @State private var showingPhoneAuth = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            // Background
            MeshGradient.safetyMesh(intensity: 0.3)
                .ignoresSafeArea()
            
            VStack(spacing: DesignTokens.spacingXLarge) {
                Spacer()
                
                // Logo and tagline
                VStack(spacing: DesignTokens.spacingMedium) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.safetyOrange)
                        .shadow(color: .safetyOrange.opacity(0.5), radius: 20)
                    
                    Text("Sanctuary")
                        .font(.displayLarge)
                        .foregroundStyle(.white)
                    
                    Text("Your safety, your boundaries")
                        .font(.bodyLarge)
                        .foregroundStyle(.textSecondary)
                }
                
                Spacer()
                
                // Error message
                if let error = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.statusWarning)
                        Text(error)
                            .font(.bodySmall)
                            .foregroundStyle(.textSecondary)
                    }
                    .padding()
                    .background(Color.statusWarning.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusSmall))
                }
                
                // Auth buttons
                VStack(spacing: DesignTokens.spacingMedium) {
                    // Sign in with Apple
                    SignInWithAppleButton { request in
                        request.requestedScopes = [.email, .fullName]
                    } onCompletion: { result in
                        handleAppleSignIn(result: result)
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: DesignTokens.buttonHeightLarge)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium))
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.borderSubtle)
                            .frame(height: 1)
                        Text("or")
                            .font(.labelMedium)
                            .foregroundStyle(.textTertiary)
                        Rectangle()
                            .fill(Color.borderSubtle)
                            .frame(height: 1)
                    }
                    
                    // Phone auth
                    Button {
                        showingPhoneAuth = true
                    } label: {
                        HStack {
                            Image(systemName: "phone.fill")
                            Text("Continue with Phone")
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.horizontal, DesignTokens.spacingLarge)
                
                // Terms
                Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                    .font(.labelSmall)
                    .foregroundStyle(.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignTokens.spacingLarge)
                    .padding(.bottom, DesignTokens.spacingLarge)
            }
            
            // Loading overlay
            if isLoading {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                
                ProgressView()
                    .tint(.safetyOrange)
                    .scaleEffect(1.5)
            }
        }
        .sheet(isPresented: $showingPhoneAuth) {
            PhoneAuthView()
        }
    }
    
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success:
            isLoading = true
            Task {
                do {
                    try await dependencies.authManager.signInWithApple()
                } catch {
                    errorMessage = error.localizedDescription
                }
                isLoading = false
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Phone Auth View

struct PhoneAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DependencyContainer.self) private var dependencies
    
    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var isCodeSent = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var countdown = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.sanctuaryBlack
                    .ignoresSafeArea()
                
                VStack(spacing: DesignTokens.spacingLarge) {
                    // Header
                    VStack(spacing: DesignTokens.spacingSmall) {
                        Image(systemName: isCodeSent ? "key.fill" : "phone.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.safetyOrange)
                        
                        Text(isCodeSent ? "Enter Code" : "Phone Number")
                            .font(.displaySmall)
                            .foregroundStyle(.white)
                        
                        Text(isCodeSent 
                             ? "We sent a code to \(phoneNumber)"
                             : "We'll send you a verification code")
                            .font(.bodyMedium)
                            .foregroundStyle(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, DesignTokens.spacingXLarge)
                    
                    Spacer()
                    
                    // Input
                    if isCodeSent {
                        // Verification code input
                        OTPInputView(code: $verificationCode)
                        
                        // Resend button
                        if countdown > 0 {
                            Text("Resend in \(countdown)s")
                                .font(.bodySmall)
                                .foregroundStyle(.textTertiary)
                        } else {
                            Button("Resend Code") {
                                sendOTP()
                            }
                            .font(.bodySmall)
                            .foregroundStyle(.safetyOrange)
                        }
                    } else {
                        // Phone number input
                        HStack {
                            Text("+1")
                                .font(.headlineMedium)
                                .foregroundStyle(.textSecondary)
                                .padding(.leading)
                            
                            TextField("(555) 123-4567", text: $phoneNumber)
                                .font(.headlineMedium)
                                .foregroundStyle(.white)
                                .keyboardType(.phonePad)
                                .textContentType(.telephoneNumber)
                        }
                        .padding()
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium)
                                .stroke(Color.borderSubtle, lineWidth: 1)
                        )
                        .padding(.horizontal)
                    }
                    
                    // Error
                    if let error = errorMessage {
                        Text(error)
                            .font(.bodySmall)
                            .foregroundStyle(.statusDanger)
                    }
                    
                    Spacer()
                    
                    // Continue button
                    Button {
                        if isCodeSent {
                            verifyOTP()
                        } else {
                            sendOTP()
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(isCodeSent ? "Verify" : "Send Code")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isLoading || (isCodeSent ? verificationCode.count < 6 : phoneNumber.count < 10))
                    .padding(.horizontal)
                    .padding(.bottom, DesignTokens.spacingLarge)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if isCodeSent {
                            isCodeSent = false
                            verificationCode = ""
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: isCodeSent ? "chevron.left" : "xmark")
                            .foregroundStyle(.textSecondary)
                    }
                }
            }
        }
    }
    
    private func sendOTP() {
        guard !phoneNumber.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Format phone number
        let formattedPhone = "+1" + phoneNumber.filter { $0.isNumber }
        
        Task {
            do {
                try await dependencies.authManager.sendPhoneOTP(phoneNumber: formattedPhone)
                isCodeSent = true
                startCountdown()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    private func verifyOTP() {
        guard verificationCode.count == 6 else { return }
        
        isLoading = true
        errorMessage = nil
        
        let formattedPhone = "+1" + phoneNumber.filter { $0.isNumber }
        
        Task {
            do {
                try await dependencies.authManager.verifyPhoneOTP(
                    phoneNumber: formattedPhone,
                    code: verificationCode
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    private func startCountdown() {
        countdown = 60
        Task {
            while countdown > 0 {
                try? await Task.sleep(for: .seconds(1))
                countdown -= 1
            }
        }
    }
}

// MARK: - OTP Input View

struct OTPInputView: View {
    @Binding var code: String
    @FocusState private var isFocused: Bool
    
    private let codeLength = 6
    
    var body: some View {
        HStack(spacing: DesignTokens.spacingSmall) {
            ForEach(0..<codeLength, id: \.self) { index in
                OTPDigitBox(
                    digit: digit(at: index),
                    isActive: index == code.count
                )
            }
        }
        .background(
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .opacity(0)
                .onChange(of: code) { _, newValue in
                    code = String(newValue.prefix(codeLength))
                }
        )
        .onTapGesture {
            isFocused = true
        }
        .onAppear {
            isFocused = true
        }
    }
    
    private func digit(at index: Int) -> String? {
        guard index < code.count else { return nil }
        return String(code[code.index(code.startIndex, offsetBy: index)])
    }
}

struct OTPDigitBox: View {
    let digit: String?
    let isActive: Bool
    
    var body: some View {
        Text(digit ?? "")
            .font(.displayMedium)
            .foregroundStyle(.white)
            .frame(width: 48, height: 56)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusSmall))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusSmall)
                    .stroke(isActive ? Color.safetyOrange : Color.borderSubtle, lineWidth: isActive ? 2 : 1)
            )
    }
}

#Preview {
    AuthenticationView()
        .environment(DependencyContainer.shared)
}
