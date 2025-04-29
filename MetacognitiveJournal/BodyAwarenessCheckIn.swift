import Foundation

/// Represents a body awareness check-in session
struct BodyAwarenessCheckIn: Codable, Identifiable {
    /// Unique identifier for the check-in
    let id: UUID
    
    /// The date when the check-in was performed
    let date: Date
    
    /// The emotion identified during the check-in
    let emotion: String
    
    /// The intensity of the emotion (0.0 to 1.0)
    let intensity: Double
    
    /// The areas of the body where the emotion was felt
    let bodyAreas: [String]
    
    /// Number of breaths taken during the breathing exercise
    let breathCount: Int
    
    /// Additional notes or observations
    let notes: String
    
    /// Creates a new body awareness check-in
    /// - Parameters:
    ///   - id: Unique identifier (defaults to a new UUID)
    ///   - date: Date of the check-in (defaults to current date)
    ///   - emotion: The emotion identified
    ///   - intensity: The intensity of the emotion (0.0 to 1.0)
    ///   - bodyAreas: The areas of the body where the emotion was felt
    ///   - breathCount: Number of breaths taken during the breathing exercise
    ///   - notes: Additional notes or observations
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        emotion: String,
        intensity: Double,
        bodyAreas: [String],
        breathCount: Int,
        notes: String
    ) {
        self.id = id
        self.date = date
        self.emotion = emotion
        self.intensity = intensity
        self.bodyAreas = bodyAreas
        self.breathCount = breathCount
        self.notes = notes
    }
}

/// Manager for storing and retrieving body awareness check-ins
class BodyAwarenessManager {
    /// Shared instance for app-wide access
    static let shared = BodyAwarenessManager()
    
    /// Key for storing check-ins in UserDefaults
    private let storageKey = "bodyAwarenessCheckIns"
    
    /// All saved check-ins
    private(set) var checkIns: [BodyAwarenessCheckIn] = []
    
    /// Private initializer to enforce singleton pattern
    private init() {
        loadCheckIns()
    }
    
    /// Saves a new body awareness check-in
    /// - Parameter checkIn: The check-in to save
    /// - Returns: Success indicator
    @discardableResult
    func saveCheckIn(_ checkIn: BodyAwarenessCheckIn) -> Bool {
        // Add to the in-memory collection
        checkIns.append(checkIn)
        
        // Sort by date (newest first)
        checkIns.sort { $0.date > $1.date }
        
        // Persist to storage
        return persistCheckIns()
    }
    
    /// Gets the most recent check-ins
    /// - Parameter limit: Maximum number of check-ins to return
    /// - Returns: Array of recent check-ins
    func getRecentCheckIns(limit: Int = 10) -> [BodyAwarenessCheckIn] {
        // Return the most recent check-ins, up to the specified limit
        return Array(checkIns.prefix(limit))
    }
    
    /// Gets the total number of check-ins performed
    var totalCheckIns: Int {
        return checkIns.count
    }
    
    /// Loads check-ins from persistent storage
    private func loadCheckIns() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            checkIns = []
            return
        }
        
        do {
            let decoder = JSONDecoder()
            checkIns = try decoder.decode([BodyAwarenessCheckIn].self, from: data)
            // Sort by date (newest first)
            checkIns.sort { $0.date > $1.date }
        } catch {
            print("[BodyAwarenessManager] Error loading check-ins: \(error.localizedDescription)")
            checkIns = []
        }
    }
    
    /// Persists check-ins to storage
    /// - Returns: Success indicator
    private func persistCheckIns() -> Bool {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(checkIns)
            UserDefaults.standard.set(data, forKey: storageKey)
            return true
        } catch {
            print("[BodyAwarenessManager] Error saving check-ins: \(error.localizedDescription)")
            return false
        }
    }
}
