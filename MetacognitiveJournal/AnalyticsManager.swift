import Foundation
import Combine

/// Types of analytics events that can be tracked
enum AnalyticsEventType: String, Codable {
    case chapterGenerated = "chapter_generated"
    case chapterViewed = "chapter_viewed"
    case genreSelected = "genre_selected"
    case storyShared = "story_shared"
    case feedbackGiven = "feedback_given"
    case userInteraction = "user_interaction"
}

/// Tracks user interactions to understand engagement patterns
struct AnalyticsEvent: Codable, Identifiable {
    var id = UUID()
    let type: AnalyticsEventType
    let timestamp: Date
    let properties: [String: String]
    let userId: String
    
    init(type: AnalyticsEventType, 
         properties: [String: String] = [:], 
         userId: String = UserDefaults.standard.string(forKey: "userId") ?? UUID().uuidString) {
        self.type = type
        self.timestamp = Date()
        self.properties = properties
        self.userId = userId
        
        // If this is the first time, save the userId
        if UserDefaults.standard.string(forKey: "userId") == nil {
            UserDefaults.standard.set(userId, forKey: "userId")
        }
    }
}

/// Manages app analytics and tracking to improve user experience
class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    private init() {
        loadEvents()
        // Start session timer
        sessionStartTime = Date()
        
        // Set up timer to periodically save events
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.saveEvents()
        }
    }
    
    // All events recorded in the current session
    @Published private(set) var events: [AnalyticsEvent] = []
    
    // Track session time
    private var sessionStartTime: Date?
    
    // Queue to handle concurrent access to events
    private let queue = DispatchQueue(label: "com.achievrai.analytics", attributes: .concurrent)
    
    // Storage key for persisting analytics events
    private let storageKey = "com.achievrai.analytics.events"
    
    /// Logs a new analytics event
    func logEvent(_ type: AnalyticsEventType, properties: [String: String] = [:]) {
        queue.async(flags: .barrier) { [weak self] in
            let event = AnalyticsEvent(type: type, properties: properties)
            self?.events.append(event)
            
            // For debugging
            print("📊 Analytics: \(type.rawValue) - \(properties)")
            
            // Save events periodically to avoid too frequent disk operations
            if self?.events.count ?? 0 % 10 == 0 {
                self?.saveEvents()
            }
        }
    }
    
    /// Tracks when a chapter is generated with specific details
    func trackChapterGeneration(genre: String, studentName: String, themes: [String]) {
        let properties: [String: String] = [
            "genre": genre,
            "student_name": studentName,
            "themes": themes.joined(separator: ","),
            "theme_count": "\(themes.count)"
        ]
        logEvent(.chapterGenerated, properties: properties)
    }
    
    /// Tracks when a user selects a specific genre
    func trackGenreSelection(genre: String) {
        logEvent(.genreSelected, properties: ["genre": genre])
    }
    
    /// Tracks when a chapter is viewed, including view duration
    func trackChapterViewed(chapterId: String, viewDuration: TimeInterval) {
        let properties: [String: String] = [
            "chapter_id": chapterId,
            "view_duration": String(format: "%.2f", viewDuration),
        ]
        logEvent(.chapterViewed, properties: properties)
    }
    
    /// Tracks when a student shares their story
    func trackStoryShared(method: String, chapterCount: Int) {
        let properties: [String: String] = [
            "sharing_method": method,
            "chapter_count": "\(chapterCount)",
        ]
        logEvent(.storyShared, properties: properties)
    }
    
    /// Tracks feedback given by users
    func trackFeedback(rating: Int, comment: String?) {
        var properties: [String: String] = ["rating": "\(rating)"]
        if let comment = comment, !comment.isEmpty {
            properties["comment"] = comment
        }
        logEvent(.feedbackGiven, properties: properties)
    }
    
    /// Get the most popular genres based on analytics
    func getPopularGenres() -> [(genre: String, count: Int)] {
        var genreCounts: [String: Int] = [:]
        
        for event in events where event.type == .genreSelected || event.type == .chapterGenerated {
            if let genre = event.properties["genre"] {
                genreCounts[genre, default: 0] += 1
            }
        }
        
        // Sort by popularity (count) in descending order
        return genreCounts.sorted { $0.value > $1.value }
                          .map { ($0.key, $0.value) }
    }
    
    /// Get the most resonant themes based on analytics
    func getResonantThemes() -> [(theme: String, count: Int)] {
        var themeCounts: [String: Int] = [:]
        
        for event in events where event.type == .chapterGenerated {
            if let themesString = event.properties["themes"] {
                let themes = themesString.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
                for theme in themes {
                    themeCounts[theme, default: 0] += 1
                }
            }
        }
        
        // Sort by resonance (count) in descending order
        return themeCounts.sorted { $0.value > $1.value }
                         .map { ($0.key, $0.value) }
    }
    
    /// Get usage insights for periods
    func getUsageInsights() -> [String: Int] {
        let calendar = Calendar.current
        var insights = [String: Int]()
        
        let todayCount = events.filter { calendar.isDateInToday($0.timestamp) }.count
        let weekCount = events.filter { calendar.isDate($0.timestamp, equalTo: Date(), toGranularity: .weekOfYear) }.count
        let monthCount = events.filter { calendar.isDate($0.timestamp, equalTo: Date(), toGranularity: .month) }.count
        
        insights["today"] = todayCount
        insights["week"] = weekCount
        insights["month"] = monthCount
        insights["total"] = events.count
        
        return insights
    }
    
    // MARK: - Private methods for persistence
    
    /// Save analytics events to local storage
    private func saveEvents() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(self.events)
                UserDefaults.standard.set(data, forKey: self.storageKey)
            } catch {
                print("Failed to save analytics events: \(error)")
            }
        }
    }
    
    /// Load analytics events from local storage
    private func loadEvents() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self,
                  let data = UserDefaults.standard.data(forKey: self.storageKey) else { return }
            
            do {
                let decoder = JSONDecoder()
                let loadedEvents = try decoder.decode([AnalyticsEvent].self, from: data)
                
                DispatchQueue.main.async {
                    self.events = loadedEvents
                    print("📊 Loaded \(loadedEvents.count) analytics events")
                }
            } catch {
                print("Failed to load analytics events: \(error)")
            }
        }
    }
}
