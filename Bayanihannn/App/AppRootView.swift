import SwiftUI

// MARK: - App Storage Keys

/// Device-level UI flags stored in UserDefaults (not app data, so they are
/// intentionally kept out of SwiftData).
enum AppStorageKeys {

    /// Set to true once the user leaves onboarding (Skip or Get Started),
    /// so onboarding is only shown the first time the app is used.
    static let hasSeenOnboarding = "hasSeenOnboarding"
}


// MARK: - App Root View

/// Phase 1: single root that switches between the signed-out flow and the
/// main tab interface based on `controller.isLoggedIn`.
///
/// Previously AppTabBarView was *pushed* onto the Splash/Login
/// NavigationStack, which nested each tab's own NavigationStack inside
/// another one. Now the tab interface is shown at the root with no outer
/// NavigationStack, so every tab owns exactly one stack. Screen designs are
/// unchanged — only where the views are hosted changed.
struct AppRootView: View {

    @Environment(BayanihanController.self) private var controller

    /// After the first login in this app session, a later logout returns
    /// straight to LoginView (matching the previous "pop back to Login"
    /// behavior) instead of replaying the splash screen.
    @State private var authFlowStartsAtLogin = false

    var body: some View {

        ZStack {

            if controller.isLoggedIn {

                AppTabBarView()
                    .transition(.move(edge: .trailing))

            } else {

                NavigationStack {

                    if authFlowStartsAtLogin {
                        LoginView()
                    } else {
                        SplashView()
                    }
                }
                .transition(.move(edge: .leading))
            }
        }
        .animation(.default, value: controller.isLoggedIn)
        .onChange(of: controller.isLoggedIn) { _, isLoggedIn in
            if isLoggedIn {
                authFlowStartsAtLogin = true
            }
        }
        .onAppear {
            // Phase 2: after an automatic login ("Remember Me"), a later
            // logout should also return straight to Login, not the splash.
            if controller.isLoggedIn {
                authFlowStartsAtLogin = true
            }
        }
    }
}


#Preview {
    AppRootView()
        .environment(BayanihanController())
}
