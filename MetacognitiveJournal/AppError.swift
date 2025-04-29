import Foundation

enum JournalAppError: LocalizedError, Equatable {
    case authenticationFailed(message: String)
    case keychainError(message: String)
    case internalError(message: String)
    case persistence

    var errorDescription: String? {
        switch self {
        case .authenticationFailed(let message): return "Authentication Failed: \(message)"
        case .keychainError(let message): return "Keychain Error: \(message)"
        case .internalError(let message): return "Internal Error: \(message)"
        case .persistence: return "Persistence Error"
        }
    }
    var icon: String {
        switch self {
        case .authenticationFailed: return "lock.fill"
        case .keychainError: return "key.fill"
        case .internalError: return "exclamationmark.triangle.fill"
        case .persistence: return "tray.fill"
        }
    }
    var message: String {
        switch self {
        case .authenticationFailed(let message): return message
        case .keychainError(let message): return message
        case .internalError(let message): return message
        case .persistence: return "Persistence Error"
        }
    }
}
