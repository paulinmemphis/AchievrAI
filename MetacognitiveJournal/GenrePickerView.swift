import SwiftUI

struct GenrePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    let genres: [String]
    let onSelect: (String) -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(genres, id: \.self) { genre in
                    Button(action: {
                        onSelect(genre)
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: iconForGenre(genre))
                                .foregroundColor(themeManager.selectedTheme.accentColor)
                            
                            Text(genre.capitalized)
                                .foregroundColor(themeManager.selectedTheme.primaryTextColor)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Select Story Genre")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func iconForGenre(_ genre: String) -> String {
        switch genre.lowercased() {
        case "fantasy":
            return "wand.and.stars"
        case "mystery":
            return "magnifyingglass"
        case "adventure":
            return "map"
        case "scifi":
            return "star"
        case "general":
            return "book"
        default:
            return "book"
        }
    }
}
