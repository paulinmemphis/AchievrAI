import SwiftUI

@main
struct MetacognitiveJournalApp: App {
    // Keep StateObjects for managers/stores here at the App level
    @StateObject private var journalStore = JournalStore() // Unsecured, temporary
    @StateObject private var analyzer = MetacognitiveAnalyzer()
    @StateObject private var parentalControlManager = ParentalControlManager()
    @StateObject private var userProfile = UserProfile()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var appLockManager = AppLockManager()
    @StateObject private var gamificationManager = GamificationManager()

    // Keep State variables for view routing logic here
    @State private var secureJournalStore: JournalStore? = nil
    @State private var isLoadingStore = true
    @State private var storeUnlockError: Error? = nil
    @State private var requiresPasswordSetup = false
    @State private var requiresPasswordEntry = false
    @State private var passwordEntryError: String? = nil // Added for password sheet error

    var body: some Scene {
        WindowGroup {
            // Instantiate RootView, passing state and functions
            RootView(
                isLoadingStore: isLoadingStore,
                requiresPasswordSetup: requiresPasswordSetup,
                bindingRequiresPasswordEntry: $requiresPasswordEntry,
                bindingPasswordEntryError: $passwordEntryError,
                storeUnlockError: storeUnlockError,
                secureJournalStore: secureJournalStore,
                onPasswordEntered: handlePasswordEntered
            )
            // Restore environment objects
            .environmentObject(analyzer)
            .environmentObject(parentalControlManager)
            .environmentObject(userProfile)
            .environmentObject(themeManager)
            .environmentObject(appLockManager)
            .environmentObject(gamificationManager)
            .task { // Keep task applied to RootView instance
                print("[App] .task started. Current state: isLoadingStore=\(isLoadingStore), requiresPasswordSetup=\(requiresPasswordSetup), requiresPasswordEntry=\(requiresPasswordEntry), secureJournalStore is nil: \(secureJournalStore == nil)")
                await loadAndUnlockStore()
                print("[App] .task finished. Final state: isLoadingStore=\(isLoadingStore), requiresPasswordSetup=\(requiresPasswordSetup), requiresPasswordEntry=\(requiresPasswordEntry), secureJournalStore is nil: \(secureJournalStore == nil)")
            }
            .sheet(isPresented: $requiresPasswordEntry) { // Use the original @State from App
                // Pass the correct bindings and callbacks for PasswordEntryView
                PasswordEntryView(errorMessage: $passwordEntryError, onPasswordEntered: handlePasswordEntered)
                    .environmentObject(themeManager) // Pass ThemeManager if needed by PasswordEntryView
            }
        }
    }

    // --- Helper Functions remain in the App struct --- 

    // loadAndUnlockStore, completeOnboarding, authenticateWithPassword, configureAppAppearance...
    // (Code for these functions is unchanged from the previous version)
    private func loadAndUnlockStore() async {
        await MainActor.run { isLoadingStore = true; storeUnlockError = nil }
        print("[Unlock] Starting loadAndUnlockStore...")
        do {
            print("[Unlock] Checking if password exists...")
            var passwordExists = false
            do {
                _ = try KeychainManager.retrieve(key: "metacognitiveJournalEncryptionPassword")
                passwordExists = true
            } catch let error as KeychainManager.KeychainError where error == .itemNotFound {
                passwordExists = false
            } catch {
                throw error
            }
            print("[Unlock] Password exists: \(passwordExists)")

            if !passwordExists {
                print("[Unlock] No password found. Requiring setup.")
                await MainActor.run {
                    requiresPasswordSetup = true
                    isLoadingStore = false
                }
                print("[Unlock] State after requiring setup: isLoadingStore=\(isLoadingStore), requiresPasswordSetup=\(requiresPasswordSetup)")
                return
            }

            print("[Unlock] Password exists. Requiring password entry.")
            await MainActor.run {
                requiresPasswordEntry = true
                isLoadingStore = false
            }
            print("[Unlock] State after requiring entry: isLoadingStore=\(isLoadingStore), requiresPasswordEntry=\(requiresPasswordEntry)")

        } catch {
            print("[Unlock] Error during initial check: \(error)")
            await MainActor.run {
                storeUnlockError = error
                isLoadingStore = false
            }
            print("[Unlock] State after error: isLoadingStore=\(isLoadingStore), storeUnlockError=\(String(describing: storeUnlockError))")
        }
    }

    private func completeOnboarding(password: String) async {
        print("[App] completeOnboarding called.")
        await MainActor.run { isLoadingStore = true }
        do {
            print("[App] Attempting to save password during onboarding...")
            try KeychainManager.save(key: "metacognitiveJournalEncryptionPassword", data: password.data(using: .utf8)!)
            print("[App] Password saved successfully.")
            let store = JournalStore()
            await MainActor.run {
                self.secureJournalStore = store
                self.requiresPasswordSetup = false
                self.isLoadingStore = false
                print("[App] Onboarding complete. secureJournalStore assigned. isLoadingStore=\(isLoadingStore), requiresPasswordSetup=\(requiresPasswordSetup)")
            }
        } catch {
            print("[App] Error saving password/loading store during onboarding: \(error)")
            await MainActor.run {
                storeUnlockError = error
                isLoadingStore = false
                print("[App] State after onboarding error: isLoadingStore=\(isLoadingStore), storeUnlockError=\(String(describing: storeUnlockError))")
            }
        }
    }

    // Renamed to clarify it's the core async logic
    private func authenticateWithPassword(password: String) async -> Bool {
        print("[App] authenticateWithPassword (async core logic) called.")
        // Clear previous error when starting attempt
        await MainActor.run { passwordEntryError = nil }

        await MainActor.run { isLoadingStore = true }
        do {
            print("[App] Attempting to retrieve password from Keychain...")
            let storedPasswordData = try KeychainManager.retrieve(key: "metacognitiveJournalEncryptionPassword")
            let storedPassword = String(data: storedPasswordData, encoding: .utf8)
            print("[App] Password retrieved from keychain.")

            if storedPassword == password {
                print("[App] Password matches. Proceeding to load store.")
                let store = JournalStore()
                print("[App] JournalStore initialized (or loaded).")
                await MainActor.run {
                    self.secureJournalStore = store
                    self.requiresPasswordEntry = false
                    self.isLoadingStore = false
                    print("[App] Authentication successful. secureJournalStore assigned. isLoadingStore=\(isLoadingStore), requiresPasswordEntry=\(requiresPasswordEntry)")
                }
                return true
            } else {
                print("[App] Password mismatch.")
                await MainActor.run {
                    self.isLoadingStore = false
                    self.passwordEntryError = "Incorrect password." // Set error message
                    print("[App] State after password mismatch: isLoadingStore=\(isLoadingStore)")
                }
                return false
            }
        } catch KeychainManager.KeychainError.itemNotFound {
            print("[App] Keychain item not found during authentication (unexpected).")
            await MainActor.run {
                storeUnlockError = KeychainManager.KeychainError.itemNotFound
                requiresPasswordEntry = false
                isLoadingStore = false
                print("[App] State after keychain item not found: isLoadingStore=\(isLoadingStore), requiresPasswordEntry=\(requiresPasswordEntry), storeUnlockError=\(String(describing: storeUnlockError))")
                self.passwordEntryError = "Keychain error during authentication." // Set error message
            }
            return false
        }
        catch {
            print("[App] Error during authentication/store loading: \(error)")
            await MainActor.run {
                storeUnlockError = error
                requiresPasswordEntry = false
                isLoadingStore = false
                print("[App] State after general authentication error: isLoadingStore=\(isLoadingStore), requiresPasswordEntry=\(requiresPasswordEntry), storeUnlockError=\(String(describing: storeUnlockError))")
                self.passwordEntryError = "Error during authentication: \(error.localizedDescription)" // Set error message
            }
            return false
        }
    }

    // Synchronous wrapper for the sheet's callback
    private func handlePasswordEntered(_ password: String) {
        print("[App] handlePasswordEntered called. Launching async task.")
        // Clear error immediately before launching task
        passwordEntryError = nil 
        Task {
            if requiresPasswordSetup {
                // If we're in password setup mode, use completeOnboarding
                await completeOnboarding(password: password)
            } else {
                // Otherwise, authenticate with existing password
                _ = await authenticateWithPassword(password: password)
            }
            print("[App] Async task within handlePasswordEntered finished.")
        }
    }

    private func configureAppAppearance() {
        print("[App] configureAppAppearance called.")
    }
}

// --- Restore RootView Struct --- 
struct RootView: View {
    // Environment Objects (kept)
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var appLockManager: AppLockManager
    @EnvironmentObject var analyzer: MetacognitiveAnalyzer
    @EnvironmentObject var parentalControlManager: ParentalControlManager
    @EnvironmentObject var gamificationManager: GamificationManager

    // State properties passed from App (kept)
    let isLoadingStore: Bool
    let requiresPasswordSetup: Bool
    @Binding var bindingRequiresPasswordEntry: Bool
    @Binding var bindingPasswordEntryError: String?
    let storeUnlockError: Error?
    let secureJournalStore: JournalStore? 

    // Closures for callbacks passed from App
    let onPasswordEntered: (String) -> Void

    @ViewBuilder // Restore @ViewBuilder
    var body: some View {
        Group { 
            if isLoadingStore {
                LoadingView(message: "Unlocking Journal...")
                    .onAppear { print("[AppEntry][RootView] Showing LoadingView") }
            } else if requiresPasswordSetup {
                // Show PasswordSetupView when password setup is required
                PasswordSetupView(onPasswordSet: { newPassword in
                    // Use the password entry callback defined in the app
                    onPasswordEntered(newPassword)
                })
                .environmentObject(themeManager)
                .onAppear { print("[AppEntry][RootView] Showing PasswordSetupView") }
             } else if let error = storeUnlockError {
                 ErrorView(error: error)
                     .onAppear { print("[AppEntry][RootView] Showing ErrorView: \(error)") }
             } else if let store = secureJournalStore { // Capture store
                 // Restore ContentView and inject store
                 ContentView()
                     .environmentObject(store)
                     .onAppear { print("[AppEntry][RootView] Showing ContentView")}
             } else {
                 // Fallback: Show nothing while waiting for sheet/action
                 EmptyView()
                     .onAppear { print("[AppEntry][RootView] Showing EmptyView (Fallback while waiting for sheet/state)")}
             }
         }
     }
}
