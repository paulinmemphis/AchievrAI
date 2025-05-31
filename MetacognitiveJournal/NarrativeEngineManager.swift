import Foundation
import Combine
import SwiftUI

/// Manages the narrative engine feature across the app
class NarrativeEngineManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isStoryGenerationEnabled = true
    @Published var defaultGenre: String = "Fantasy"
    @Published var showWritingPrompts = true
    @Published var showGenreSelection = false
    
    // MARK: - Private Properties
    private let persistenceManager = StoryPersistenceManager.shared
    private let offlineQueue = OfflineRequestQueue.shared
    private var networkMonitor = NetworkMonitor.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Constants
    private enum Constants {
        static let genreKey = "preferred_story_genre"
        static let enabledKey = "story_generation_enabled"
        static let promptsKey = "show_writing_prompts"
    }
    
    // MARK: - Init
    init() {
        // Load user preferences
        loadPreferences()
        
        // Setup monitoring for network changes
        setupNetworkMonitoring()
        
        // Setup configuration
        setupConfiguration()
    }
    
    // MARK: - Public Methods
    
    /// Toggles story generation feature
    func toggleStoryGeneration() {
        isStoryGenerationEnabled.toggle()
        UserDefaults.standard.set(isStoryGenerationEnabled, forKey: Constants.enabledKey)
    }
    
    /// Sets the default genre for story generation
    /// - Parameter genre: The genre key to use as default
    func setDefaultGenre(_ genre: String) {
        guard NarrativeEngineConstants.genres[genre] != nil else { return }
        defaultGenre = genre
        UserDefaults.standard.set(genre, forKey: Constants.genreKey)
        
        // Log the genre selection for analytics
        print("[NarrativeEngineManager] Genre set to: \(genre)")
    }
    
    /// Shows the genre selection view
    func showGenreSelectionView() {
        showGenreSelection = true
    }
    
    /// Hides the genre selection view
    func hideGenreSelectionView() {
        showGenreSelection = false
    }
    
    /// Toggles whether to show writing prompts
    func toggleWritingPrompts() {
        showWritingPrompts.toggle()
        UserDefaults.standard.set(showWritingPrompts, forKey: Constants.promptsKey)
    }
    
    /// Processes any pending offline requests
    func processOfflineRequests() {
        if networkMonitor.isConnected {
            DispatchQueue.main.async {
                self.offlineQueue.processAllPendingRequests()
            }
        }
    }
    
    /// Gets the number of pending requests
    var pendingRequestCount: Int {
        offlineQueue.pendingRequestCount
    }
    
    /// Gets story chapters for a user
    /// - Returns: Publisher that emits story nodes or error
    func getStoryNodes() -> AnyPublisher<[StoryNode], Error> {
        return persistenceManager.getAllStoryNodes()
    }
    
    // MARK: - Private Methods
    
    /// Loads user preferences
    private func loadPreferences() {
        // Load genre preference
        if let savedGenre = UserDefaults.standard.string(forKey: Constants.genreKey),
           NarrativeEngineConstants.genres[savedGenre] != nil {
            defaultGenre = savedGenre
        } else {
            // If no valid genre is saved, use the first available genre
            defaultGenre = "Fantasy"
        }
        
        // Load enabled state
        isStoryGenerationEnabled = UserDefaults.standard.bool(forKey: Constants.enabledKey)
        
        // Load prompts preference
        if UserDefaults.standard.object(forKey: Constants.promptsKey) != nil {
            showWritingPrompts = UserDefaults.standard.bool(forKey: Constants.promptsKey)
        }
    }
    
    /// Sets up network monitoring
    private func setupNetworkMonitoring() {
        networkMonitor.$isConnected
            .dropFirst() // Skip initial value
            .filter { $0 } // Only when connected
            .sink { [weak self] _ in
                self?.processOfflineRequests()
            }
            .store(in: &cancellables)
    }
    
    /// Sets up initial configuration
    private func setupConfiguration() {
        // If there are no saved preferences, set defaults
        if UserDefaults.standard.object(forKey: Constants.enabledKey) == nil {
            UserDefaults.standard.set(true, forKey: Constants.enabledKey)
        }
        
        if UserDefaults.standard.object(forKey: Constants.promptsKey) == nil {
            UserDefaults.standard.set(true, forKey: Constants.promptsKey)
        }
        
        if UserDefaults.standard.object(forKey: Constants.genreKey) == nil {
            UserDefaults.standard.set("fantasy", forKey: Constants.genreKey)
        }
    }
}
