import Foundation
import SwiftUI

/// Stores user profile data, including name for personalization.
class UserProfile: ObservableObject {
    @AppStorage("userName") var name: String = "Student"
}
