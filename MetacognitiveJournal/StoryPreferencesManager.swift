import Foundation
import SwiftUI

/// Manages user preferences related to story generation
class StoryPreferencesManager: ObservableObject {
    /// Shared instance for app-wide access
    static let shared = StoryPreferencesManager()
    
    /// Published property for default genre with @AppStorage for persistence
    @AppStorage("defaultGenre") var defaultGenre: String = "Fantasy"
    
    /// Published property for favorite genres
    @Published var favoriteGenres: [String] = []
    
    /// Key for storing favorite genres in UserDefaults
    private let favoriteGenresKey = "favoriteGenres"
    private let genreHistoryKey = "genreHistory"
    
    /// Initialize the preferences manager
    init() {
        loadFavoriteGenres()
    }
    
    /// Toggle a genre as favorite
    func toggleFavorite(genre: String) {
        if favoriteGenres.contains(genre) {
            favoriteGenres.removeAll { $0 == genre }
        } else {
            favoriteGenres.append(genre)
        }
        saveFavoriteGenres()
    }
    
    /// Check if a genre is in favorites
    func isFavorite(genre: String) -> Bool {
        return favoriteGenres.contains(genre)
    }
    
    /// Save favorite genres to UserDefaults
    private func saveFavoriteGenres() {
        if let encoded = try? JSONEncoder().encode(favoriteGenres) {
            UserDefaults.standard.set(encoded, forKey: favoriteGenresKey)
        }
    }
    
    /// Load favorite genres from UserDefaults
    private func loadFavoriteGenres() {
        if let data = UserDefaults.standard.data(forKey: favoriteGenresKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            favoriteGenres = decoded
        }
    }
    
    /// History of selected genres for analytics
    func addToGenreHistory(genre: String) {
        // Get existing history
        var history = genreHistory
        
        // Remove the genre if it already exists in the history
        history.removeAll { $0 == genre }
        
        // Add the new genre to history (at the beginning)
        history.insert(genre, at: 0)
        
        // Limit to 10 recent selections
        if history.count > 10 {
            history = Array(history.prefix(10))
        }
        
        // Save updated history
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: genreHistoryKey)
        }
    }
    
    /// Get genre selection history
    var genreHistory: [String] {
        if let data = UserDefaults.standard.data(forKey: genreHistoryKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            return decoded
        }
        return []
    }
}
