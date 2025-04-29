// GenreSelectionView.swift
import SwiftUI

/// Model for storing genre information
struct Genre: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let description: String
    let icon: String // SF Symbol name
    let imageName: String // Asset name for preview image
    let sampleText: String // Sample text in this genre style
    let keywords: [String] // Key themes and elements of this genre
    
    static let allGenres: [Genre] = [
        Genre(name: "Fantasy", 
              description: "Magical worlds with mythical creatures, wizards, and epic quests", 
              icon: "wand.and.stars",
              imageName: "fantasy_preview", 
              sampleText: "The ancient spell glowed between Elara's fingertips as the dragon circled overhead. This was her moment to prove herself to the Council of Mages.",
              keywords: ["magic", "quests", "creatures", "kingdoms", "heroes"]),
        
        Genre(name: "Sci-Fi", 
              description: "Future technology, space exploration, and scientific discoveries", 
              icon: "helm.of.mercury",
              imageName: "scifi_preview", 
              sampleText: "The neural interface hummed as Captain Vega connected to the ship's AI. 'Status report on the quantum drive,' she commanded silently.",
              keywords: ["technology", "space", "future", "discovery", "aliens"]),
        
        Genre(name: "Mystery", 
              description: "Puzzling events, clues, and detective work to solve a case", 
              icon: "magnifyingglass",
              imageName: "mystery_preview", 
              sampleText: "Detective Harlow examined the peculiar markings on the door. 'The victim knew their assailant,' he murmured, 'this wasn't random.'",
              keywords: ["detective", "clues", "suspects", "investigation", "reveal"]),
        
        Genre(name: "Adventure", 
              description: "Exciting journeys filled with challenges and discoveries", 
              icon: "map",
              imageName: "adventure_preview", 
              sampleText: "The ancient map led them to the edge of the waterfall. 'The temple must be hidden behind it,' Alex said, securing the climbing rope.",
              keywords: ["journey", "exploration", "danger", "treasure", "wilderness"]),
        
        Genre(name: "Romance", 
              description: "Relationships, emotional connections, and personal growth", 
              icon: "heart",
              imageName: "romance_preview", 
              sampleText: "Their eyes met across the crowded room, and suddenly the music seemed to fade. Jordan knew in that moment everything was about to change.",
              keywords: ["love", "relationships", "emotions", "connection", "growth"]),
        
        Genre(name: "Historical", 
              description: "Stories set in the past with authentic historical elements", 
              icon: "clock.arrow.circlepath",
              imageName: "historical_preview", 
              sampleText: "The year was 1863, and as the cannons sounded in the distance, Eleanor knew her family's plantation would never be the same.",
              keywords: ["past", "events", "era", "figures", "authenticity"]),
        
        Genre(name: "Thriller", 
              description: "Suspenseful situations with high stakes and danger", 
              icon: "exclamationmark.triangle",
              imageName: "thriller_preview", 
              sampleText: "The timer on the device ticked down as Morgan frantically searched for the disarm code. Only two minutes remained.",
              keywords: ["suspense", "danger", "chase", "urgency", "threat"]),
        
        Genre(name: "Comedy", 
              description: "Humorous situations and witty dialogue to entertain", 
              icon: "face.smiling",
              imageName: "comedy_preview", 
              sampleText: "As the wedding cake slowly tipped over, Casey made a diving catch that landed them face-first in the frosting. The guests erupted in laughter.",
              keywords: ["humor", "laughter", "wit", "irony", "situational"]),
        
        Genre(name: "Educational", 
              description: "Learning-focused narratives with academic concepts", 
              icon: "book",
              imageName: "educational_preview", 
              sampleText: "'The mitochondria,' explained Professor Lee, 'is like the power plant of the cell.' Sarah suddenly visualized tiny workers in an energy factory.",
              keywords: ["learning", "concepts", "discovery", "knowledge", "understanding"]),
        
        Genre(name: "Sports", 
              description: "Athletic pursuits, teamwork, and competition", 
              icon: "figure.run",
              imageName: "sports_preview", 
              sampleText: "Down by two with seconds on the clock, Riley took a deep breath and stepped up to the free-throw line. Everything had led to this moment.",
              keywords: ["competition", "teamwork", "victory", "challenge", "perseverance"])
    ]
    
    // Default placeholder image for preview
    var previewImage: Image {
        // Try to load the specific image, fall back to a placeholder if not found
        return Image(imageName)
    }
}

/// A simplified view that allows users to select a genre for their narrative story
struct GenreSelectionView: View {
    @Binding var selectedGenre: String
    @Binding var isPresented: Bool
    
    // For animations
    @Namespace private var animation
    
    // Genre-specific colors
    private func colorForGenre(_ genre: String) -> Color {
        switch genre {
        case "Fantasy": return .purple
        case "Sci-Fi": return .blue
        case "Mystery": return .indigo
        case "Adventure": return .green
        case "Romance": return .pink
        case "Historical": return .brown
        case "Thriller": return .red
        case "Comedy": return .orange
        case "Educational": return .teal
        case "Sports": return .mint
        default: return .blue
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Choose a Genre")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Select a genre for your personalized story")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Grid of genre options
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 180), spacing: 16)], spacing: 16) {
                    ForEach(Genre.allGenres) { genre in
                        GenreCard(
                            genre: genre, 
                            isSelected: genre.name == selectedGenre
                        )
                        .onTapGesture {
                            withAnimation(.spring()) {
                                selectedGenre = genre.name
                                isPresented = false
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }
}

// MARK: - Genre Card
struct GenreCard: View {
    let genre: Genre
    let isSelected: Bool
    
    // Genre-specific colors
    private func colorForGenre(_ genre: String) -> Color {
        switch genre {
        case "Fantasy": return .purple
        case "Sci-Fi": return .blue
        case "Mystery": return .indigo
        case "Adventure": return .green
        case "Romance": return .pink
        case "Historical": return .brown
        case "Thriller": return .red
        case "Comedy": return .orange
        case "Educational": return .teal
        case "Sports": return .mint
        default: return .blue
        }
    }
    
    var body: some View {
        VStack {
            // Icon and favorite button
            ZStack {
                // Circle with icon
                ZStack {
                    Circle()
                        .fill(isSelected ? colorForGenre(genre.name) : colorForGenre(genre.name).opacity(0.2))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: genre.icon)
                        .font(.title)
                        .foregroundColor(isSelected ? .white : colorForGenre(genre.name))
                }
                .padding(8)
            }
                
            Text(genre.name)
                .font(.headline)
                .foregroundColor(isSelected ? colorForGenre(genre.name) : .primary)
        }
        .frame(height: 140)
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? colorForGenre(genre.name).opacity(0.2) : Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Preview
struct GenreSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        GenreSelectionView(selectedGenre: .constant("Adventure"), isPresented: .constant(true))
            .previewLayout(.sizeThatFits)
    }
}
