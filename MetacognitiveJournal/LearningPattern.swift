import Foundation

enum LearningPattern: String, Codable, CaseIterable, Hashable {
    case visualLearner
    case auditoryLearner
    case handsonLearner
    case contextualLearner
    case abstractLearner
    case reflectiveThinker
    case activeThinker
    case sequentialProcessor
    case holisticProcessor
    
    var keywords: [String] {
        switch self {
        case .visualLearner:
            return ["diagram", "picture", "visual", "see", "image", "visualization", "color", "looked", "watch"]
        case .auditoryLearner:
            return ["heard", "listen", "sound", "audio", "told", "talk", "discuss", "explain verbally", "said"]
        case .handsonLearner:
            return ["practice", "hands-on", "try", "build", "create", "experiment", "physical", "touch", "do"]
        case .contextualLearner:
            return ["example", "context", "real-world", "application", "story", "case", "situation", "scenario"]
        case .abstractLearner:
            return ["theory", "concept", "principle", "abstract", "idea", "framework", "model", "system"]
        case .reflectiveThinker:
            return ["think", "reflect", "consider", "ponder", "contemplate", "analyze", "review", "evaluate"]
        case .activeThinker:
            return ["act", "start", "dive in", "jump", "immediately", "quickly", "action", "direct", "right away"]
        case .sequentialProcessor:
            return ["step", "sequence", "order", "process", "procedure", "systematic", "linear", "methodical"]
        case .holisticProcessor:
            return ["whole", "big picture", "overall", "general", "holistic", "entire", "comprehensive", "broad"]
        }
    }
    
    var recommendations: [String] {
        switch self {
        case .visualLearner:
            return [
                "Create mind maps or concept diagrams to visualize relationships.",
                "Use color-coding and visual organizers in your notes.",
                "Convert text into diagrams or sketches when possible."
            ]
        case .auditoryLearner:
            return [
                "Record yourself explaining concepts and play them back.",
                "Participate in discussions or group reviews.",
                "Read aloud or listen to educational audio content."
            ]
        case .handsonLearner:
            return [
                "Engage in simulations, labs, or real-world practice.",
                "Use physical models to reinforce learning.",
                "Apply what you learn through experimentation."
            ]
        case .contextualLearner:
            return [
                "Start with concrete examples before abstract theory.",
                "Relate content to real-life scenarios or stories.",
                "Use case studies to understand application."
            ]
        case .abstractLearner:
            return [
                "Focus on underlying principles and systems.",
                "Group ideas into conceptual categories.",
                "Build your own models to understand relationships."
            ]
        case .reflectiveThinker:
            return [
                "Pause often to reflect on what you've learned.",
                "Write summaries or self-explanations.",
                "Compare your approaches to expert solutions."
            ]
        case .activeThinker:
            return [
                "Dive into activities right away.",
                "Practice through quizzes, flashcards, or building things.",
                "Set deadlines to keep moving quickly."
            ]
        case .sequentialProcessor:
            return [
                "Create detailed step-by-step plans.",
                "Use checklists or outlines when learning.",
                "Focus on logical order and progression."
            ]
        case .holisticProcessor:
            return [
                "Start with an overview before diving into details.",
                "Create visual summaries of the entire concept.",
                "Look for connections between topics to see the big picture."
            ]
        }
    }
}
