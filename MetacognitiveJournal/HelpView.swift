import SwiftUI

struct HelpView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Getting Started")) {
                    NavigationLink(value: HelpTopic.newEntry) {
                        HelpRow(icon: "pencil.circle.fill", title: "Creating Journal Entries")
                    }
                    
                    NavigationLink(value: HelpTopic.storyGeneration) {
                        HelpRow(icon: "book.fill", title: "Generating Story Chapters")
                    }
                    
                    NavigationLink(value: HelpTopic.storyMap) {
                        HelpRow(icon: "map.fill", title: "Exploring Your Story Map")
                    }
                    
                    NavigationLink(value: HelpTopic.reminders) {
                        HelpRow(icon: "bell.fill", title: "Setting Journal Reminders")
                    }
                }
                
                Section(header: Text("Story Features")) {
                    NavigationLink(value: HelpTopic.genres) {
                        HelpRow(icon: "theatermasks.fill", title: "Understanding Story Genres")
                    }
                    
                    NavigationLink(value: HelpTopic.arcs) {
                        HelpRow(icon: "chart.line.uptrend.xyaxis", title: "Narrative Arcs and Themes")
                    }
                    
                    NavigationLink(value: HelpTopic.export) {
                        HelpRow(icon: "square.and.arrow.up", title: "Exporting Your Story")
                    }
                }
                
                Section(header: Text("FAQs")) {
                    NavigationLink(value: HelpTopic.privacy) {
                        HelpRow(icon: "lock.shield.fill", title: "Privacy and Data Storage")
                    }
                    
                    NavigationLink(value: HelpTopic.ai) {
                        HelpRow(icon: "cpu", title: "How the AI Works")
                    }
                    
                    NavigationLink(value: HelpTopic.troubleshooting) {
                        HelpRow(icon: "wrench.fill", title: "Troubleshooting")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Help & Onboarding")
            .background(themeManager.selectedTheme.backgroundColor.edgesIgnoringSafeArea(.all))
            .navigationDestination(for: HelpTopic.self) { topic in
                HelpDetailView(topic: topic)
            }
        }
    }
}

// MARK: - Help Topic Enum

enum HelpTopic: Int, Identifiable {
    case newEntry, storyGeneration, storyMap, reminders
    case genres, arcs, export
    case privacy, ai, troubleshooting
    
    var id: Int { self.rawValue }
    
    var title: String {
        switch self {
        case .newEntry: return "Creating Journal Entries"
        case .storyGeneration: return "Generating Story Chapters"
        case .storyMap: return "Exploring Your Story Map"
        case .reminders: return "Setting Journal Reminders"
        case .genres: return "Understanding Story Genres"
        case .arcs: return "Narrative Arcs and Themes"
        case .export: return "Exporting Your Story"
        case .privacy: return "Privacy and Data Storage"
        case .ai: return "How the AI Works"
        case .troubleshooting: return "Troubleshooting"
        }
    }
    
    var icon: String {
        switch self {
        case .newEntry: return "pencil.circle.fill"
        case .storyGeneration: return "book.fill"
        case .storyMap: return "map.fill"
        case .reminders: return "bell.fill"
        case .genres: return "theatermasks.fill"
        case .arcs: return "chart.line.uptrend.xyaxis"
        case .export: return "square.and.arrow.up"
        case .privacy: return "lock.shield.fill"
        case .ai: return "cpu"
        case .troubleshooting: return "wrench.fill"
        }
    }
    
    var content: [HelpContent] {
        switch self {
        case .newEntry:
            return [
                HelpContent(title: "Creating a New Journal Entry", text: "Tap the + button on the Journal tab to create a new entry. You can select a subject, assignment name, and your emotional state.", image: "plus.circle.fill"),
                HelpContent(title: "Voice Journaling", text: "Use the microphone button to dictate your journal entry. The app will transcribe your spoken words into text.", image: "mic.fill"),
                HelpContent(title: "Adding Details", text: "Include specific details about your day, feelings, and learning experiences for the richest story generation later.", image: "text.bubble.fill")
            ]
            
        case .storyGeneration:
            return [
                HelpContent(title: "How Stories Are Created", text: "After saving a journal entry, your personal narrative is transformed into a story chapter. Each entry becomes a new chapter in your ongoing story.", image: "book.closed.fill"),
                HelpContent(title: "Viewing Generated Chapters", text: "Navigate to the Story Map to see all your generated chapters. Tap on any node to read the corresponding story segment.", image: "book.pages.fill"),
                HelpContent(title: "Consistent Characters", text: "Your story maintains consistent characters and settings while developing an engaging narrative arc based on your journal entries.", image: "person.2.fill")
            ]
            
        case .storyMap:
            return [
                HelpContent(title: "Navigating the Story Map", text: "The Story Map shows the connections between your journal entries and generated story chapters. Use pinch gestures to zoom in and out.", image: "map"),
                HelpContent(title: "Understanding Nodes", text: "Each node represents a chapter of your story. Connected nodes show the narrative progression and relationships between events.", image: "circle.grid.cross.fill"),
                HelpContent(title: "Visualization Modes", text: "Switch between timeline, tree, and web visualizations to see different perspectives of your story's development.", image: "square.3.stack.3d")
            ]
            
        case .reminders:
            return [
                HelpContent(title: "Setting Up Reminders", text: "Go to Settings > Reminders to configure journal entry reminders. You can set daily or custom schedules.", image: "timer"),
                HelpContent(title: "Notification Types", text: "Choose between standard notifications or reflection prompts that inspire deeper journaling.", image: "bell.badge.fill"),
                HelpContent(title: "Managing Reminders", text: "Edit or delete existing reminders by swiping left on them in the Reminders list.", image: "slider.horizontal.3")
            ]
            
        case .genres:
            return [
                HelpContent(title: "Available Story Genres", text: "Select from fantasy, science fiction, mystery, adventure, or slice-of-life genres to shape how your journal entries are transformed.", image: "books.vertical.fill"),
                HelpContent(title: "Changing Genres", text: "You can change your preferred genre at any time from the Settings > Story Preferences menu. This will affect future chapters only.", image: "arrow.triangle.2.circlepath"),
                HelpContent(title: "Genre Effects", text: "Each genre has unique characteristics that influence your story's setting, tone, and narrative elements.", image: "wand.and.stars")
            ]
            
        case .arcs:
            return [
                HelpContent(title: "Story Arcs Explained", text: "The app analyzes emotional patterns and themes in your journal entries to create meaningful narrative arcs that develop over time.", image: "chart.line.uptrend.xyaxis"),
                HelpContent(title: "Theme Identification", text: "Key words and sentiments are extracted from your entries to identify recurring themes that shape your story.", image: "tag.fill"),
                HelpContent(title: "Character Development", text: "Characters in your story evolve based on the emotional journey reflected in your journal entries.", image: "person.fill.viewfinder")
            ]
            
        case .export:
            return [
                HelpContent(title: "Exporting Your Story", text: "Tap the export button in the Story Map view to save your complete story as a PDF or text file.", image: "arrow.up.doc.fill"),
                HelpContent(title: "Sharing Options", text: "Share your story directly to social media, email, or messaging apps using the share sheet.", image: "square.and.arrow.up"),
                HelpContent(title: "Print Your Story", text: "Use the print option to create a physical copy of your personal narrative journey.", image: "printer.fill")
            ]
            
        case .privacy:
            return [
                HelpContent(title: "Local Data Storage", text: "By default, all journal entries and generated stories are stored locally on your device with complete encryption.", image: "iphone"),
                HelpContent(title: "Cloud Sync Options", text: "If enabled, you can securely sync your data across devices using end-to-end encryption.", image: "icloud.fill"),
                HelpContent(title: "Data Privacy", text: "Your journal entries are processed to generate stories, but all personal data remains private and is never shared with third parties.", image: "hand.raised.fill")
            ]
            
        case .ai:
            return [
                HelpContent(title: "Natural Language Processing", text: "The app uses advanced AI to understand the context, emotions, and key elements in your journal entries.", image: "text.viewfinder"),
                HelpContent(title: "Metadata Extraction", text: "The system identifies sentiment, topics, named entities, and key phrases from your writing to build meaningful story connections.", image: "doc.text.magnifyingglass"),
                HelpContent(title: "Chapter Generation", text: "GPT-4 transforms your journal metadata into coherent story chapters that maintain continuity while adding creative elements.", image: "sparkles")
            ]
            
        case .troubleshooting:
            return [
                HelpContent(title: "Story Generation Issues", text: "If story generation seems slow or fails, check your internet connection and try again. For persistent issues, use the 'Regenerate' option in the Story tab.", image: "arrow.clockwise"),
                HelpContent(title: "Data Recovery", text: "Go to Settings > Backup & Restore to recover any lost journal entries or generated stories.", image: "arrow.counterclockwise"),
                HelpContent(title: "Contact Support", text: "For technical issues, tap Settings > Help & Support > Contact Us to reach our support team.", image: "envelope.fill")
            ]
        }
    }
}

// MARK: - Help Row Component

struct HelpRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.accentColor)
                .frame(width: 32, height: 32)
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Help Content Model

struct HelpContent: Identifiable {
    let id = UUID()
    let title: String
    let text: String
    let image: String
}

// MARK: - Welcome Help View

struct WelcomeHelpView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles.rectangle.stack.fill")
                .font(.system(size: 60))
                .foregroundColor(themeManager.selectedTheme.accentColor)
                .padding(.bottom, 10)
            
            Text("Welcome to Metacognitive Journal")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Transform your journal entries into a personalized story")
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 15) {
                FeatureRow(icon: "pencil.and.outline", title: "Reflect on your experiences", description: "Journal about your day, thoughts, and feelings")
                
                FeatureRow(icon: "wand.and.stars", title: "Generate personalized stories", description: "AI transforms your entries into narrative chapters")
                
                FeatureRow(icon: "map", title: "Explore your story map", description: "See how your entries connect in a visual journey")
                
                FeatureRow(icon: "doc.richtext", title: "Track meaningful patterns", description: "Discover themes and arcs in your personal narrative")
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
            .padding(.horizontal)
            
            Text("Select a topic from the menu to learn more")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Feature Row Component

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundColor(.accentColor)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Help Detail View

struct HelpDetailView: View {
    let topic: HelpTopic
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    Image(systemName: topic.icon)
                        .font(.system(size: 36))
                        .foregroundColor(themeManager.selectedTheme.accentColor)
                        .padding(.trailing, 8)
                    
                    Text(topic.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .padding(.bottom, 8)
                
                // Content sections
                ForEach(topic.content) { content in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: content.image)
                                .font(.system(size: 22))
                                .foregroundColor(themeManager.selectedTheme.accentColor)
                                .frame(width: 30, height: 30)
                            
                            Text(content.title)
                                .font(.headline)
                        }
                        
                        Text(content.text)
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.leading, 38)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                }
            }
            .padding()
        }
        .navigationTitle(topic.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(themeManager.selectedTheme.backgroundColor.edgesIgnoringSafeArea(.all))
    }
}

// MARK: - Preview Provider

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView()
            .environmentObject(ThemeManager())
    }
}
