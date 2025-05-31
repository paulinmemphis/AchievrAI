import Foundation
import SwiftUI

/// Stores user profile data, including name for personalization.
enum AgeGroup: String, CaseIterable, Identifiable, Codable {
    case child, teen, adult, parent
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .child: return "Child (6-12)"
        case .teen: return "Teen (13-17)"
        case .adult: return "Adult (18+)"
        case .parent: return "Parent"
        }
    }
}

class UserProfile: ObservableObject {
    @AppStorage("userName") var name: String = "Student"
    @AppStorage("userAgeGroup") private var ageGroupRaw: String = AgeGroup.child.rawValue
    @AppStorage("userBirthday") private var birthdayTimeInterval: Double = Date().timeIntervalSince1970
    
    var ageGroup: AgeGroup {
        get { AgeGroup(rawValue: ageGroupRaw) ?? .child }
        set { ageGroupRaw = newValue.rawValue }
    }
    
    var birthday: Date {
        get { Date(timeIntervalSince1970: birthdayTimeInterval) }
        set { birthdayTimeInterval = newValue.timeIntervalSince1970 }
    }
    
    var age: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthday, to: Date())
        return ageComponents.year ?? 0
    }
    
    func setAgeGroup(_ group: AgeGroup) {
        ageGroup = group
        objectWillChange.send()
    }
    
    func setBirthday(_ date: Date) {
        birthday = date
        updateAgeGroupFromBirthday()
        objectWillChange.send()
    }
    
    func updateAgeGroupFromBirthday() {
        let currentAge = age
        
        if currentAge < 13 {
            ageGroup = .child
        } else if currentAge < 18 {
            ageGroup = .teen
        } else {
            ageGroup = .adult
        }
    }
}
