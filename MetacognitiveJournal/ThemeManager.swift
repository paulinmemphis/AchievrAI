import SwiftUI

/// Manages the currently selected theme for the application.
///
/// This class conforms to `ObservableObject` to publish theme changes to SwiftUI views.
/// It persists the selected theme using `UserDefaults`.
class ThemeManager: ObservableObject {
    /// The key used to store the selected theme's raw value in UserDefaults.
    private let themeKey = "selectedTheme"

    /// The currently selected theme. Published to update SwiftUI views upon changes.
    @AppStorage("selectedTheme") var selectedTheme: Theme = .system

    /// Initializes the ThemeManager and loads the previously selected theme from UserDefaults,
    /// defaulting to `.system` if none was saved.
    init() {
        let savedThemeRawValue = UserDefaults.standard.string(forKey: themeKey)
        self.selectedTheme = Theme(rawValue: savedThemeRawValue ?? Theme.system.rawValue) ?? .system
    }

    /// Updates the selected theme and saves the new selection to UserDefaults.
    /// - Parameter theme: The `Theme` to set as the current theme.
    func setTheme(_ theme: Theme) {
        selectedTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: themeKey)
    }

    /// Defines the available themes for the application.
    enum Theme: String, CaseIterable, Identifiable {
        case system = "System Default"
        case light = "Light"
        case dark = "Dark"
        case ocean = "Ocean"
        case forest = "Forest"
        case sunset = "Sunset"

        /// Provides a stable identifier for each theme case.
        var id: String { self.rawValue }

        /// Returns the appropriate `ColorScheme` based on the theme.
        /// For `.system`, it returns `nil` to let the system decide.
        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            case .ocean, .forest, .sunset: return .light // Custom themes use light mode as base
            }
        }

        /// Provides the primary color associated with the theme.
        /// Returns a default color if the theme doesn't have a specific primary color defined.
        var accentColor: Color {
            switch self {
            case .system, .light: return .accentColor
            case .dark: return Color(red: 0.3, green: 0.65, blue: 0.9) // Bright blue for dark theme
            case .ocean: return Color(red: 0.0, green: 0.47, blue: 0.75) // Accessible blue
            case .forest: return Color(red: 0.15, green: 0.55, blue: 0.3) // Accessible green
            case .sunset: return Color(red: 0.85, green: 0.4, blue: 0.2) // Accessible orange
            }
        }

        /// Provides the background color associated with the theme.
        var backgroundColor: Color {
            switch self {
            case .system, .light:
                return Color(.systemGroupedBackground)
            case .dark:
                return Color(red: 0.12, green: 0.12, blue: 0.14) // Slightly softer than pure black
            case .ocean:
                return Color(red: 0.85, green: 0.92, blue: 0.97) // Light blue background
            case .forest:
                return Color(red: 0.88, green: 0.95, blue: 0.9) // Light green background
            case .sunset:
                return Color(red: 0.98, green: 0.95, blue: 0.9) // Light warm background
            }
        }
        
        /// Provides the text color associated with the theme.
        var textColor: Color {
            switch self {
            case .system, .light:
                return Color(red: 0.15, green: 0.15, blue: 0.15) // Slightly softer than pure black
            case .dark:
                return Color(red: 0.97, green: 0.97, blue: 0.99) // Brighter white for better contrast
            case .ocean:
                return Color(red: 0.1, green: 0.25, blue: 0.45) // Dark blue text for light background
            case .forest:
                return Color(red: 0.1, green: 0.35, blue: 0.25) // Dark green text for light background
            case .sunset:
                return Color(red: 0.4, green: 0.2, blue: 0.1) // Dark orange/brown text for light background
            }
        }
        
        /// Provides the color for images and icons to ensure they're visible in all themes
        var imageColor: Color {
            switch self {
            case .system, .light:
                return Color(red: 0.3, green: 0.3, blue: 0.35) // Dark gray for light backgrounds
            case .dark:
                return Color(red: 0.85, green: 0.85, blue: 0.9) // Light gray for dark backgrounds - brighter than standard
            case .ocean:
                return Color(red: 0.0, green: 0.3, blue: 0.6) // Darker blue for light background
            case .forest:
                return Color(red: 0.15, green: 0.4, blue: 0.25) // Darker green for light background
            case .sunset:
                return Color(red: 0.6, green: 0.3, blue: 0.15) // Darker orange for light background
            }
        }
    }
}
