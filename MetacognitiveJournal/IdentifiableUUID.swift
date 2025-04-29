import Foundation

/// A wrapper around UUID that conforms to Identifiable
struct IdentifiableUUID: Identifiable, Hashable {
    var id: UUID
    
    init(_ uuid: UUID) {
        self.id = uuid
    }
}
