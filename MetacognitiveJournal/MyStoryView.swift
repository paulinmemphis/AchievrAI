import SwiftUI

struct MyStoryView: View {
    @EnvironmentObject var storyManager: StoryManager
    @EnvironmentObject var themeManager: ThemeManager 

    
    @State private var storyNodeViewModels: [StoryNodeViewModel] = []

    var body: some View {
        
        
        
        NavigationStack {
            Group {
                if storyNodeViewModels.isEmpty {
                    Text("Your story is just beginning!")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    List {
                        ForEach(storyNodeViewModels) { vm in
                            NavigationLink(value: vm) { 
                                VStack(alignment: .leading) {
                                    Text(vm.title)
                                        .font(.headline)
                                        .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                                    Text("Themes: \(vm.themes.isEmpty ? "N/A" : vm.themes.joined(separator: ", "))")
                                        .font(.caption)
                                        .foregroundColor(themeManager.selectedTheme.secondaryTextColor)
                                        .lineLimit(1)
                                    Text("Sentiment: \(vm.sentimentDescriptionText)")
                                        .font(.caption)
                                        .foregroundColor(vm.sentimentColor)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("My Story Chapters")
            .navigationDestination(for: StoryNodeViewModel.self) { vm in 
                ChapterView(nodeViewModel: vm)
                    .environmentObject(themeManager) 
                    
            }
            .onAppear {
                loadStoryData()
            }
            .background(themeManager.selectedTheme.backgroundColor.edgesIgnoringSafeArea(.all))
        }
    }

    private func loadStoryData() {
        let nodes = storyManager.getAllStoryNodes() 
        self.storyNodeViewModels = nodes.compactMap { node in
            if let chapter = storyManager.getChapter(byId: node.chapterId) {
                return StoryNodeViewModel(node: node, chapter: chapter)
            }
            return nil
        }
    }
}

struct MyStoryView_Previews: PreviewProvider {
    static var previews: some View {
        
        let mockStoryManager = StoryManager()
        
        
        // Sample data for first chapter
        let entry1Text = "Today was a grand adventure in the Whispering Woods with Elara. We found an old oak tree that seemed to hum with magic."
        let entry1Id = "entry1-preview"
        mockStoryManager.generateAndAddChapter(forJournalEntryText: entry1Text, entryId: entry1Id, genre: .fantasy)

        // Sample data for second chapter
        let entry2Text = "Detective Kael is on a new case. So many hidden clues and unsolved mysteries. The city's secrets are deep."
        let entry2Id = "entry2-preview"
        mockStoryManager.generateAndAddChapter(forJournalEntryText: entry2Text, entryId: entry2Id, genre: .mystery)
        
        // The generateAndAddChapter method in StoryManager already sorts storyNodes and adds chapters.


        return MyStoryView()
            .environmentObject(mockStoryManager)
            .environmentObject(ThemeManager())
    }
}
