import SwiftUI

/// Manages the currently selected theme for the application.
///
/// This class conforms to `ObservableObject` to publish theme changes to SwiftUI views.
/// It persists the selected theme using `UserDefaults`.
class ThemeManager: ObservableObject {
    /// The key used to store the selected theme's raw value in UserDefaults.
    private let themeKey = "selectedTheme"
    private let childThemeKey = "childSelectedTheme"

    /// The currently selected theme. Published to update SwiftUI views upon changes.
    @AppStorage("selectedTheme") var selectedTheme: Theme = .system
    
    /// The currently selected child theme. Published to update SwiftUI views upon changes.
    @AppStorage("childSelectedTheme") var selectedChildTheme: ChildTheme = .rainbow

    /// Initializes the ThemeManager and loads the previously selected theme from UserDefaults,
    /// defaulting to `.system` if none was saved.
    init() {
        let savedThemeRawValue = UserDefaults.standard.string(forKey: themeKey)
        self.selectedTheme = Theme(rawValue: savedThemeRawValue ?? Theme.system.rawValue) ?? .system
        
        let savedChildThemeRawValue = UserDefaults.standard.string(forKey: childThemeKey)
        self.selectedChildTheme = ChildTheme(rawValue: savedChildThemeRawValue ?? ChildTheme.rainbow.rawValue) ?? .rainbow
    }

    /// Updates the selected theme and saves the new selection to UserDefaults.
    /// - Parameter theme: The `Theme` to set as the current theme.
    func setTheme(_ theme: Theme) {
        selectedTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: themeKey)
    }
    
    /// Updates the selected child theme and saves the new selection to UserDefaults.
    /// - Parameter theme: The `ChildTheme` to set as the current child theme.
    func setChildTheme(_ theme: ChildTheme) {
        selectedChildTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: childThemeKey)
    }
    
    /// Gets the appropriate theme for a child based on their journal mode
    /// - Parameter mode: The child's journal mode based on developmental stage
    /// - Returns: The appropriate theme properties
    func themeForChildMode(_ mode: ChildJournalMode) -> Theme {
        switch mode {
        case .earlyChildhood:
            return selectedChildTheme.toTheme()
        case .middleChildhood:
            return selectedChildTheme.toTheme()
        case .adolescent:
            return selectedTheme
        }
    }

    /// Defines the available themes for the application.
    enum Theme: String, CaseIterable, Identifiable {
        case system = "System Default"
        case light = "Light"
        case dark = "Dark"
        case ocean = "Ocean"
        case forest = "Forest"
        case sunset = "Sunset"
        case rainbow = "Rainbow"
        case space = "Space Adventure"
        case jungle = "Jungle Safari"
        case underwater = "Underwater"
        case dinosaur = "Dinosaur World"

        /// Provides a stable identifier for each theme case.
        var id: String { self.rawValue }

        /// Returns the appropriate `ColorScheme` based on the theme.
        /// For `.system`, it returns `nil` to let the system decide.
        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            case .ocean, .forest, .sunset, .rainbow, .space, .jungle, .underwater, .dinosaur: return .light
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
            case .sunset: return Color(red: 0.9, green: 0.4, blue: 0.2) // Accessible orange
            case .rainbow: return Color(red: 0.6, green: 0.4, blue: 0.8) // Purple
            case .space: return Color(red: 0.7, green: 0.7, blue: 0.9) // Light gray-blue
            case .jungle: return Color(red: 0.2, green: 0.6, blue: 0.3) // Jungle green
            case .underwater: return Color(red: 0.1, green: 0.6, blue: 0.8) // Deep cyan
            case .dinosaur: return Color(red: 0.6, green: 0.5, blue: 0.3) // Brown
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
            case .rainbow:
                return Color(red: 0.95, green: 0.95, blue: 1.0) // Light violet background
            case .space:
                return Color(red: 0.05, green: 0.05, blue: 0.15) // Deep space blue
            case .jungle:
                return Color(red: 0.9, green: 0.98, blue: 0.88) // Light jungle green
            case .underwater:
                return Color(red: 0.88, green: 0.95, blue: 1.0) // Light cyan background
            case .dinosaur:
                return Color(red: 0.95, green: 0.92, blue: 0.88) // Light tan background
            }
        }
        
        /// Provides the text color associated with the theme.
        /// Returns a default color if the theme doesn't have a specific primary color defined.
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
            case .rainbow:
                return Color(red: 0.3, green: 0.2, blue: 0.4) // Dark purple
            case .space:
                return Color(red: 0.9, green: 0.9, blue: 0.95) // Light text for dark background
            case .jungle:
                return Color(red: 0.1, green: 0.35, blue: 0.15) // Dark jungle green
            case .underwater:
                return Color(red: 0.05, green: 0.3, blue: 0.5) // Deep blue text
            case .dinosaur:
                return Color(red: 0.4, green: 0.3, blue: 0.15) // Dark brown text
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
            case .rainbow:
                return Color(red: 0.5, green: 0.4, blue: 0.6) // Muted purple
            case .space:
                return Color(red: 0.7, green: 0.7, blue: 0.8) // Lighter text for dark background
            case .jungle:
                return Color(red: 0.25, green: 0.5, blue: 0.3) // Muted jungle green
            case .underwater:
                return Color(red: 0.2, green: 0.5, blue: 0.7) // Muted blue text
            case .dinosaur:
                return Color(red: 0.6, green: 0.5, blue: 0.4) // Muted brown text
            }
        }
        
        /// Provides the secondary text color associated with the theme.
        var secondaryTextColor: Color {
            switch self {
            case .system, .light: return .secondary
            case .dark: return Color(.systemGray)
            case .ocean: return Color(red: 0.4, green: 0.5, blue: 0.6)
            case .forest: return Color(red: 0.4, green: 0.5, blue: 0.45)
            case .sunset: return Color(red: 0.6, green: 0.5, blue: 0.4)
            case .rainbow: return Color(red: 0.5, green: 0.4, blue: 0.6) // Muted purple
            case .space: return Color(red: 0.7, green: 0.7, blue: 0.8) // Lighter text for dark background
            case .jungle: return Color(red: 0.25, green: 0.5, blue: 0.3) // Muted jungle green
            case .underwater: return Color(red: 0.2, green: 0.5, blue: 0.7) // Muted blue text
            case .dinosaur: return Color(red: 0.6, green: 0.5, blue: 0.4) // Muted brown text
            }
        }
        
        /// Provides the background color for card-like elements.
        var cardBackgroundColor: Color {
            switch self {
            case .system, .light: return Color(.secondarySystemGroupedBackground)
            case .dark: return Color(white: 0.18)
            case .ocean, .forest, .sunset, .rainbow, .space, .jungle, .underwater, .dinosaur: return Color.white
            }
        }
        
        /// Provides the color for placeholder text.
        var placeholderColor: Color {
            switch self {
            case .system, .light: return Color(.placeholderText)
            case .dark: return Color(.systemGray3)
            case .ocean, .forest, .sunset, .rainbow, .space, .jungle, .underwater, .dinosaur: return Color(.systemGray2)
            }
        }
        
        /// Provides the background color for input fields.
        var inputBackgroundColor: Color {
            switch self {
            case .system, .light: return Color(.systemGray6)
            case .dark: return Color(white: 0.22)
            case .ocean, .forest, .sunset, .rainbow, .space, .jungle, .underwater, .dinosaur: return Color(white: 0.98)
            }
        }
        
        /// Provides the color for dividers and separators.
        var dividerColor: Color {
            switch self {
            case .system, .light: return Color(.separator)
            case .dark: return Color(white: 0.3)
            case .ocean, .forest, .sunset, .rainbow, .space, .jungle, .underwater, .dinosaur: return Color(.systemGray4)
            }
        }

        /// Alias for primary text color clarity.
        var primaryTextColor: Color { self.textColor }
        
        /// Returns whether this theme is child-friendly
        var isChildFriendly: Bool {
            switch self {
            case .rainbow, .space, .jungle, .underwater, .dinosaur:
                return true
            default:
                return false
            }
        }
        
        /// Returns the theme's icon name
        var iconName: String {
            switch self {
            case .system: return "gear"
            case .light: return "sun.max"
            case .dark: return "moon.stars"
            case .ocean: return "water.waves"
            case .forest: return "leaf"
            case .sunset: return "sunset"
            case .rainbow: return "rainbow"
            case .space: return "star"
            case .jungle: return "leaf.fill"
            case .underwater: return "drop"
            case .dinosaur: return "fossil"
            }
        }
        
        /// Returns a fun description for child themes
        var childDescription: String? {
            switch self {
            case .rainbow: return "Colorful and bright!"
            case .space: return "Explore the stars!"
            case .jungle: return "Adventure in the wild!"
            case .underwater: return "Dive into the ocean!"
            case .dinosaur: return "Roar like a T-Rex!"
            default: return nil
            }
        }
    }
    
    /// Child-specific themes with more playful and engaging colors
    enum ChildTheme: String, CaseIterable, Identifiable {
        case rainbow = "Rainbow"
        case space = "Space Adventure"
        case jungle = "Jungle Safari"
        case underwater = "Underwater"
        case dinosaur = "Dinosaur World"
        
        var id: String { self.rawValue }
        
        /// Converts a child theme to the corresponding main theme
        func toTheme() -> Theme {
            switch self {
            case .rainbow: return .rainbow
            case .space: return .space
            case .jungle: return .jungle
            case .underwater: return .underwater
            case .dinosaur: return .dinosaur
            }
        }
        
        /// Returns the theme's icon name
        var iconName: String {
            switch self {
            case .rainbow: return "rainbow"
            case .space: return "star"
            case .jungle: return "leaf.fill"
            case .underwater: return "drop"
            case .dinosaur: return "fossil"
            }
        }
        
        /// Returns a fun description for the theme
        var description: String {
            switch self {
            case .rainbow: return "Colorful and bright!"
            case .space: return "Explore the stars!"
            case .jungle: return "Adventure in the wild!"
            case .underwater: return "Dive into the ocean!"
            case .dinosaur: return "Roar like a T-Rex!"
            }
        }
        
        /// Returns the primary color for this child theme
        var primaryColor: Color {
            switch self {
            case .rainbow: return Color(red: 0.9, green: 0.2, blue: 0.3) // Bright red
            case .space: return Color(red: 0.3, green: 0.0, blue: 0.6) // Deep purple
            case .jungle: return Color(red: 0.0, green: 0.6, blue: 0.3) // Vibrant green
            case .underwater: return Color(red: 0.0, green: 0.5, blue: 0.8) // Ocean blue
            case .dinosaur: return Color(red: 0.6, green: 0.4, blue: 0.1) // Amber
            }
        }
        
        /// Returns secondary accent colors for this theme
        var secondaryColors: [Color] {
            switch self {
            case .rainbow: 
                return [
                    Color(red: 0.9, green: 0.2, blue: 0.3), // Red
                    Color(red: 1.0, green: 0.6, blue: 0.0), // Orange
                    Color(red: 1.0, green: 0.9, blue: 0.0), // Yellow
                    Color(red: 0.0, green: 0.8, blue: 0.2), // Green
                    Color(red: 0.0, green: 0.5, blue: 1.0), // Blue
                    Color(red: 0.5, green: 0.0, blue: 0.8)  // Purple
                ]
            case .space:
                return [
                    Color(red: 0.3, green: 0.0, blue: 0.6), // Deep purple
                    Color(red: 0.0, green: 0.0, blue: 0.3), // Dark blue
                    Color(red: 1.0, green: 0.8, blue: 0.0), // Gold
                    Color(red: 0.8, green: 0.0, blue: 0.3)  // Pink
                ]
            case .jungle:
                return [
                    Color(red: 0.0, green: 0.6, blue: 0.3), // Vibrant green
                    Color(red: 0.8, green: 0.6, blue: 0.0), // Mustard
                    Color(red: 0.5, green: 0.3, blue: 0.0), // Brown
                    Color(red: 1.0, green: 0.4, blue: 0.0)  // Orange
                ]
            case .underwater:
                return [
                    Color(red: 0.0, green: 0.5, blue: 0.8), // Ocean blue
                    Color(red: 0.0, green: 0.7, blue: 0.7), // Teal
                    Color(red: 0.5, green: 0.8, blue: 1.0), // Light blue
                    Color(red: 0.0, green: 0.3, blue: 0.5)  // Deep blue
                ]
            case .dinosaur:
                return [
                    Color(red: 0.6, green: 0.4, blue: 0.1), // Amber
                    Color(red: 0.3, green: 0.5, blue: 0.2), // Moss green
                    Color(red: 0.7, green: 0.3, blue: 0.2), // Terra cotta
                    Color(red: 0.5, green: 0.5, blue: 0.5)  // Stone gray
                ]
            }
        }
        
        /// Returns whether this theme is appropriate for the given age
        func isAppropriateFor(age: Int) -> Bool {
            // All themes are appropriate for all ages, but we could implement age restrictions if needed
            return true
        }
        
        /// Returns whether this theme is appropriate for the given journal mode
        func isAppropriateFor(mode: ChildJournalMode) -> Bool {
            switch mode {
            case .earlyChildhood:
                // All themes are good for early childhood
                return true
            case .middleChildhood:
                // All themes are good for middle childhood
                return true
            case .adolescent:
                // For adolescents, space and underwater might be more mature
                switch self {
                case .space, .underwater: return true
                default: return false
                }
            }
        }
    }
}
