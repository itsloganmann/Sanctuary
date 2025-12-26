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
    @State private var showingEmailAuth = false
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
                
                // Error message
                if let error = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.statusWarning)
                        Text(error)
                            .font(.bodySmall)
                            .foregroundStyle(Color.textSecondary)
                    }
                    .padding()
                    .background(Color.statusWarning.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusSmall))
                }
                
                // Auth buttons
                VStack(spacing: DesignTokens.spacingMedium) {
                    // Phone auth - Primary option (no Apple Dev account needed)
                    Button {
                        showingPhoneAuth = true
                    } label: {
                        HStack {
                            Image(systemName: "phone.fill")
                            Text("Continue with Phone")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    // Email auth - Secondary option (no Apple Dev account needed)
                    Button {
                        showingEmailAuth = true
                    } label: {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Continue with Email")
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    #if DEBUG
                    // Debug bypass for testing
                    Button {
                        Task {
                            await dependencies.authManager.debugSignIn()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "wrench.and.screwdriver")
                            Text("Skip Auth (Debug)")
                        }
                        .font(.labelMedium)
                        .foregroundStyle(Color.textTertiary)
                    }
                    .padding(.top, DesignTokens.spacingSmall)
                    #endif
                }
                .padding(.horizontal, DesignTokens.spacingLarge)
                
                // Terms
                Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                    .font(.labelSmall)
                    .foregroundStyle(Color.textTertiary)
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
        .sheet(isPresented: $showingEmailAuth) {
            EmailAuthView()
        }
    }
}

// MARK: - Email Auth View

struct EmailAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DependencyContainer.self) private var dependencies
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.sanctuaryBlack
                    .ignoresSafeArea()
                
                VStack(spacing: DesignTokens.spacingLarge) {
                    // Header
                    VStack(spacing: DesignTokens.spacingSmall) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(Color.safetyOrange)
                        
                        Text(isSignUp ? "Create Account" : "Sign In")
                            .font(.displaySmall)
                            .foregroundStyle(.white)
                        
                        Text(isSignUp ? "Enter your email and create a password" : "Enter your email and password")
                            .font(.bodyMedium)
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, DesignTokens.spacingXLarge)
                    
                    Spacer()
                    
                    // Input fields
                    VStack(spacing: DesignTokens.spacingMedium) {
                        // Email
                        TextField("Email", text: $email)
                            .font(.bodyLarge)
                            .foregroundStyle(.white)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium)
                                    .stroke(Color.borderSubtle, lineWidth: 1)
                            )
                        
                        // Password
                        SecureField("Password", text: $password)
                            .font(.bodyLarge)
                            .foregroundStyle(.white)
                            .textContentType(isSignUp ? .newPassword : .password)
                            .padding()
                            .background(Color.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium)
                                    .stroke(Color.borderSubtle, lineWidth: 1)
                            )
                        
                        // Confirm password (sign up only)
                        if isSignUp {
                            SecureField("Confirm Password", text: $confirmPassword)
                                .font(.bodyLarge)
                                .foregroundStyle(.white)
                                .textContentType(.newPassword)
                                .padding()
                                .background(Color.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium))
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium)
                                        .stroke(Color.borderSubtle, lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Error/Success messages
                    if let error = errorMessage {
                        Text(error)
                            .font(.bodySmall)
                            .foregroundStyle(Color.statusDanger)
                    }
                    
                    if let success = successMessage {
                        Text(success)
                            .font(.bodySmall)
                            .foregroundStyle(Color.statusSafe)
                    }
                    
                    // Toggle sign up / sign in
                    Button {
                        withAnimation {
                            isSignUp.toggle()
                            errorMessage = nil
                            successMessage = nil
                        }
                    } label: {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .font(.bodySmall)
                            .foregroundStyle(Color.safetyOrange)
                    }
                    
                    Spacer()
                    
                    // Submit button
                    Button {
                        if isSignUp {
                            signUp()
                        } else {
                            signIn()
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(isSignUp ? "Create Account" : "Sign In")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isLoading || !isFormValid)
                    .padding(.horizontal)
                    .padding(.bottom, DesignTokens.spacingLarge)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        let emailValid = email.contains("@") && email.contains(".")
        let passwordValid = password.count >= 6
        
        if isSignUp {
            return emailValid && passwordValid && password == confirmPassword
        }
        return emailValid && passwordValid
    }
    
    private func signIn() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await dependencies.authManager.signInWithEmail(email: email, password: password)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    private func signUp() {
        guard password == confirmPassword else {
            errorMessage = "Passwords don't match"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await dependencies.authManager.signUpWithEmail(email: email, password: password)
                successMessage = "Check your email to confirm your account!"
                // Don't dismiss - user needs to confirm email first
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
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
                            .foregroundStyle(Color.safetyOrange)
                        
                        Text(isCodeSent ? "Enter Code" : "Phone Number")
                            .font(.displaySmall)
                            .foregroundStyle(.white)
                        
                        Text(isCodeSent 
                             ? "We sent a code to \(phoneNumber)"
                             : "We'll send you a verification code")
                            .font(.bodyMedium)
                            .foregroundStyle(Color.textSecondary)
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
                                .foregroundStyle(Color.textTertiary)
                        } else {
                            Button("Resend Code") {
                                sendOTP()
                            }
                            .font(.bodySmall)
                            .foregroundStyle(Color.safetyOrange)
                        }
                    } else {
                        // Phone number input
                        HStack {
                            Text("+1")
                                .font(.headlineMedium)
                                .foregroundStyle(Color.textSecondary)
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
                            .foregroundStyle(Color.statusDanger)
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
                            .foregroundStyle(Color.textSecondary)
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
