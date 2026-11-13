import SwiftUI

struct LoginView: View {
    
    @Environment(BayanihanController.self) private var controller

    @State private var email = ""
    @State private var password = ""
    @State private var rememberMe = false
    @State private var showPassword = false

    // Phase 2: real sign-in state (no visual change except the error alert).
    @State private var isSubmitting = false
    @State private var showLoginError = false
    @State private var loginErrorMessage = ""

    // Phase 6: Forgot Password / Apple sign-in are deferred until online
    // accounts (Firebase); a system alert explains this instead of the
    // buttons doing nothing.
    @State private var showUnavailableAlert = false
    @State private var unavailableTitle = ""
    @State private var unavailableMessage = ""

    var body: some View {
        ZStack {
            Color(
                red: 0.95,
                green: 0.98,
                blue: 0.97
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {

                    // MARK: - Branding

                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                Color(
                                    red: 0.00,
                                    green: 0.55,
                                    blue: 0.45
                                )
                            )

                        Image(systemName: "person.2.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 56, height: 56)
                    .padding(.top, 30)

                    // MARK: - Header

                    VStack(spacing: 8) {
                        Text("Welcome Back")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.black)
                        
                        Text("Sign in to continue helping your community.")
                            .font(.system(size: 13))
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 18)
                    
                    // MARK: - Login Form
                    
                    VStack(alignment: .leading, spacing: 18) {
                        
                        // Email
                        VStack(alignment: .leading, spacing: 7) {
                            Text("Email or Username")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.black)
                            
                            TextField(
                                "Enter your email or username",
                                text: $email
                            )
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .padding(.horizontal, 14)
                            .frame(height: 48)
                            .background(.white)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 12)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        Color.gray.opacity(0.2),
                                        lineWidth: 1
                                    )
                            }
                        }
                        
                        // Password
                        VStack(alignment: .leading, spacing: 7) {
                            Text("Password")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.black)
                            
                            HStack {
                                if showPassword {
                                    TextField(
                                        "Enter your password",
                                        text: $password
                                    )
                                } else {
                                    SecureField(
                                        "Enter your password",
                                        text: $password
                                    )
                                }
                                
                                Button {
                                    showPassword.toggle()
                                } label: {
                                    Image(
                                        systemName: showPassword
                                        ? "eye.slash"
                                        : "eye"
                                    )
                                    .foregroundStyle(.gray)
                                }
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 48)
                            .background(.white)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 12)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        Color.gray.opacity(0.2),
                                        lineWidth: 1
                                    )
                            }
                        }
                        
                        // Remember Me + Forgot Password
                        HStack {
                            Button {
                                rememberMe.toggle()
                            } label: {
                                HStack(spacing: 7) {
                                    Image(
                                        systemName: rememberMe
                                        ? "checkmark.square.fill"
                                        : "square"
                                    )
                                    .foregroundStyle(
                                        Color(
                                            red: 0.00,
                                            green: 0.55,
                                            blue: 0.45
                                        )
                                    )
                                    
                                    Text("Remember Me")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.gray)
                                }
                            }
                            
                            Spacer()
                            
                            Button("Forgot Password?") {
                                // Phase 6: deferred until online accounts.
                                showUnavailable(
                                    title: "Password Reset Unavailable",
                                    message: "Password reset will be available when online accounts are added. For now, please log in with your current password or create a new account."
                                )
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(
                                Color(
                                    red: 0.00,
                                    green: 0.55,
                                    blue: 0.45
                                )
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 35)
                    
                    // MARK: - Log In Button
                    
                    Button {
                        // Phase 2: verifies the email/username + password.
                        logIn()
                    } label: {
                        Text("Log In")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                Color(
                                    red: 0.00,
                                    green: 0.55,
                                    blue: 0.45
                                )
                            )
                            .clipShape(
                                RoundedRectangle(cornerRadius: 12)
                            )
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 25)
                    
                    // MARK: - Divider
                    
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 1)
                        
                        Text("OR")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.gray)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 25)
                    
                    // MARK: - Apple Login
                    
                    Button {
                        // Phase 6: deferred until online accounts.
                        showUnavailable(
                            title: "Sign in with Apple Unavailable",
                            message: "Sign in with Apple will be available when online accounts are added. Please log in with your email or username, or create an account."
                        )
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "apple.logo")
                            
                            Text("Continue with Apple")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(.white)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 12)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    Color.gray.opacity(0.2),
                                    lineWidth: 1
                                )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 18)
                    
                    // MARK: - Sign Up
                    
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundStyle(.gray)
                        
                        NavigationLink {
                            SignUpView()
                        } label: {
                            Text("Sign Up")
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    Color(
                                        red: 0.00,
                                        green: 0.55,
                                        blue: 0.45
                                    )
                                )
                        }
                    }
                    .font(.system(size: 12))
                    .padding(.top, 25)

                    // MARK: - Footer

                    Text("Bayanihan · Community Assistance Platform")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(
                            Color(
                                red: 0.35,
                                green: 0.68,
                                blue: 0.62
                            )
                        )
                        .padding(.top, 18)
                        .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        // Phase 1: the tab interface is no longer pushed from here. A
        // successful login sets `controller.isLoggedIn`, which makes
        // AppRootView switch to AppTabBarView at the root.
        .alert(
            "Unable to Log In",
            isPresented: $showLoginError
        ) {

            Button("OK", role: .cancel) {
            }

        } message: {

            Text(loginErrorMessage)
        }
        // Phase 6: explains deferred features (system alert).
        .alert(
            unavailableTitle,
            isPresented: $showUnavailableAlert
        ) {

            Button("OK", role: .cancel) {
            }

        } message: {

            Text(unavailableMessage)
        }
    }

    private func showUnavailable(
        title: String,
        message: String
    ) {
        unavailableTitle = title
        unavailableMessage = message
        showUnavailableAlert = true
    }


    // MARK: - Log In (Phase 2)

    private func logIn() {

        guard !isSubmitting else {
            return
        }

        isSubmitting = true

        Task {

            defer {
                isSubmitting = false
            }

            do {
                try await controller.login(
                    identifier: email,
                    password: password,
                    rememberMe: rememberMe
                )
            } catch {
                loginErrorMessage = error.localizedDescription
                showLoginError = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environment(BayanihanController())
    }
}