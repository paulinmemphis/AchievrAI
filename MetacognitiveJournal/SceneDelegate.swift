import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    // Create shared instances of environment objects
    private let journalStore = JournalStore()
    private let analyzer = MetacognitiveAnalyzer()
    private let parentalControlManager = ParentalControlManager()
    private let userProfile = UserProfile()
    private let themeManager = ThemeManager()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Configure app appearance
        configureAppAppearance()
        
        // Create the content view with all required environment objects
        let contentView = ContentView()
            .environmentObject(journalStore)
            .environmentObject(analyzer)
            .environmentObject(parentalControlManager)
            .environmentObject(userProfile)
            .environmentObject(themeManager)
            .accentColor(themeManager.selectedTheme.accentColor)
            .preferredColorScheme(themeManager.selectedTheme.colorScheme)

        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called when the scene is being released by the system
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background
    }
    
    private func configureAppAppearance() {
        // Set up global appearance defaults
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(Color.primary)]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(Color.primary)]
    }
}
