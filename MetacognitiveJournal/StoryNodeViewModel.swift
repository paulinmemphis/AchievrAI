import SwiftUI
import Combine 


class StoryNodeViewModel: ObservableObject, Identifiable {
    let node: StoryNode
    let chapter: StoryChapter
    
    var id: String { node.id } 

    

    var chapterId: String {
        return chapter.id
    }

    
    
    var chapterPreview: String {
        return chapter.text
    }

    
    
    
    
    var explicitCliffhanger: String? {
        return chapter.cliffhanger
    }

    
    var themes: [String] {
        return node.metadataSnapshot?.themes ?? []
    }

    
    var sentiment: Double {
        return node.metadataSnapshot?.sentimentScore ?? 0.0 
    }

    
    var sentimentColor: Color {
        let score = sentiment
        if score > 0.5 {
            return .green
        } else if score > 0.1 {
            return .yellow
        } else if score < -0.5 {
            return .red
        } else if score < -0.1 {
            return .orange
        } else {
            return .gray 
        }
    }
    
    
    
    var title: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Chapter from \(formatter.string(from: node.createdAt))"
    }
    
    
    
    var sentimentDescriptionText: String {
        let score = sentiment
        if score > 0.5 {
            return "Very Positive"
        } else if score > 0.1 {
            return "Positive"
        } else if score < -0.5 {
            return "Very Negative"
        } else if score < -0.1 {
            return "Negative"
        } else {
            return "Neutral"
        }
    }


    init(node: StoryNode, chapter: StoryChapter) {
        self.node = node
        self.chapter = chapter
    }
}


extension StoryNodeViewModel: Hashable {
    static func == (lhs: StoryNodeViewModel, rhs: StoryNodeViewModel) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
