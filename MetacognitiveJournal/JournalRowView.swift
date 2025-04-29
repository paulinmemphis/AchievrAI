import SwiftUI

/// A view representing a single row in the journal list.
struct JournalRowView: View {
    // Support both types of journal entries
    let entry: Any

    // Computed properties to handle either type
    private var title: String {
        if let multiModalEntry = entry as? MultiModal.JournalEntry {
            return multiModalEntry.title
        } else if let standardEntry = entry as? JournalEntry {
            return standardEntry.assignmentName
        }
        return "Unknown Entry"
    }
    
    private var date: Date {
        if let multiModalEntry = entry as? MultiModal.JournalEntry {
            return multiModalEntry.createdAt
        } else if let standardEntry = entry as? JournalEntry {
            return standardEntry.date
        }
        return Date()
    }
    
    private var hasDrawing: Bool {
        if let multiModalEntry = entry as? MultiModal.JournalEntry {
            return multiModalEntry.mediaItems.contains(where: { $0.type == .drawing })
        }
        return false
    }
    
    private var hasPhoto: Bool {
        if let multiModalEntry = entry as? MultiModal.JournalEntry {
            return multiModalEntry.mediaItems.contains(where: { $0.type == .photo })
        }
        return false
    }
    
    private var hasAudio: Bool {
        if let multiModalEntry = entry as? MultiModal.JournalEntry {
            return multiModalEntry.mediaItems.contains(where: { $0.type == .audio })
        }
        return false
    }
    
    private var textSnippet: String? {
        if let multiModalEntry = entry as? MultiModal.JournalEntry,
           let textItem = multiModalEntry.mediaItems.first(where: { $0.type == .text }),
           let text = textItem.textContent {
            return text
        }
        return nil
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .lineLimit(nil) // Allow title wrapping

                // Show text snippet if available
                if let text = textSnippet {
                    Text(text)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(2) // Show a couple of lines
                }

                Text(date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Media Type Icons - only show for MultiModal entries
            if entry is MultiModal.JournalEntry {
                HStack(spacing: 6) {
                    if hasDrawing {
                        Image(systemName: "pencil.tip.crop.circle")
                            .foregroundColor(.orange)
                    }
                    if hasPhoto {
                        Image(systemName: "photo.circle")
                            .foregroundColor(.blue)
                    }
                    if hasAudio {
                        Image(systemName: "mic.circle")
                            .foregroundColor(.red)
                    }
                }
                .font(.caption) // Smaller icons
            }
        }
        .padding(.vertical, 8)
    }
}
