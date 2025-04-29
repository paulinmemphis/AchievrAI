# Narrative Co-Creation Engine

## Overview

The Narrative Co-Creation Engine transforms journal entries into personalized story chapters, creating an evolving narrative that reflects the student's emotional journey. This README provides technical details about the implementation, architecture, and usage of this feature.

## Architecture

The system follows a client-server architecture:

### Backend (Node.js + Express)

- **Metadata Extraction API**: Analyzes journal text for themes, sentiment, characters, settings
- **Chapter Generation API**: Creates personalized story chapters based on metadata and preferred genres
- **Server Optimizations**: Rate limiting, response caching, error handling

### Mobile Frontend (SwiftUI + Combine)

- **API Services**: Communicates with the backend using asynchronous networking
- **Data Models**: Represents story nodes, chapters, metadata, and story arcs
- **User Interface**: Interactive journal entry, genre selection, chapter display, and story visualization

## Key Components

### Data Models

- **MetadataResponse**: Themes, sentiment, characters, settings, key insights
- **ChapterGenerationRequest**: Metadata, user ID, genre, student name, previous arcs
- **ChapterResponse**: Chapter ID, text, cliffhanger, metadata, student name, feedback
- **StoryNode**: Represents a node in the story tree (entry ID, chapter ID, parent ID, metadata, chapter, timestamp)
- **StoryArc**: Captures narrative continuity elements (summary, chapter ID, themes, timestamp)

### Services

- **NarrativeAPIService**: Handles communication with the backend
- **StoryPersistenceManager**: Manages storage and retrieval of story nodes and arcs
- **SecretManager**: Securely stores API keys and credentials
- **AnalyticsManager**: Tracks user engagement patterns
- **NetworkErrorManager**: Handles offline scenarios and network errors

### Views

- **AIJournalEntryView**: Multi-step journal entry creation with AI integration
- **GenreSelectionView**: Allows selection of narrative genres
- **ChapterView**: Displays generated chapters with personalized feedback
- **EnhancedStoryMapView**: Visualizes the story journey with multiple modes:
  - Tree View: Shows structural relationships
  - Timeline View: Chronological progression
  - Thematic View: Groups by themes

## Workflow

1. **Journal Entry Creation**:
   - Student writes a journal entry about their experiences
   - Entry is saved locally with encryption

2. **Metadata Extraction**:
   - Entry text is sent to the metadata API
   - API analyzes text for themes, sentiment, characters, settings
   - Results are returned as structured metadata

3. **Genre Selection**:
   - Student selects a preferred genre for their story
   - Options include fantasy, sci-fi, mystery, adventure, etc.

4. **Chapter Generation**:
   - Metadata, genre, and previous arcs are sent to generation API
   - API creates a personalized chapter that continues the narrative
   - Chapter includes a cliffhanger and personalized feedback

5. **Story Visualization**:
   - New chapter is added to the student's story journey
   - Story map updates to show relationships between entries
   - Analytics track engagement patterns

## Features

### Narrative Continuity

The engine maintains continuity across chapters through several mechanisms:

- **Story Arcs**: Track themes and narrative elements across chapters
- **Previous Arc Integration**: Each generation request includes summaries of recent arcs
- **Character Consistency**: Main characters persist throughout the narrative
- **Thematic Development**: Themes evolve but maintain coherence

### Visualization Options

The enhanced story map provides multiple ways to visualize narrative progression:

- **Tree View**: Shows hierarchical relationships between chapters
- **Timeline View**: Displays chronological progression
- **Thematic View**: Groups chapters by shared themes
- **Theme Highlighting**: Emphasizes specific themes across chapters

### Offline Support

The system is resilient to network disruptions:

- **Offline Detection**: Monitors network connectivity
- **Request Queueing**: Stores requests when offline
- **Automatic Retry**: Processes queued requests when connection is restored
- **Visual Indicators**: Shows network status with retry options

### Analytics

The system tracks engagement patterns to improve the experience:

- **Chapter Generation**: Records genres, themes, and generation frequency
- **Chapter Viewing**: Tracks view duration and engagement
- **Genre Selection**: Identifies preferred genres
- **Story Sharing**: Monitors sharing behavior
- **Theme Resonance**: Identifies themes that engage students

### Sharing and Collaboration

Students can share their personalized stories:

- **System Sharing**: Integrates with iOS sharing functionality
- **Formatted Text**: Creates well-formatted story snippets
- **Reading Experience**: Optimized for sharing and reading

## Security and Performance

### Security

- **API Key Management**: Secure storage in iOS Keychain
- **Server Authentication**: Request-scoped API keys
- **No Hardcoded Secrets**: All sensitive data stored in secure locations

### Performance Optimizations

- **Response Caching**: Reduces API calls for frequently accessed data
- **Rate Limiting**: Prevents API abuse
- **Retry Logic**: Handles transient errors with exponential backoff
- **Background Processing**: Long operations run asynchronously

## Testing

Several tools are available for testing the narrative engine:

- **StoryMapVisualTester**: Dedicated testing harness with sample data
- **Preview Support**: SwiftUI previews for different themes and device sizes
- **Integration Tests**: Comprehensive tests for API services
- **Unit Tests**: Tests for core components and edge cases

## Getting Started

### Prerequisites

- **Backend**: Node.js, Express, OpenAI API key
- **iOS**: Xcode 12+, iOS 14+, SwiftUI, Combine

### Configuration

1. **Backend Setup**:
   ```bash
   cd narrative-engine-server
   npm install
   # Create a .env file with your OpenAI API key
   echo "OPENAI_API_KEY=your_key_here" > .env
   npm start
   ```

2. **iOS Configuration**:
   - Open MetacognitiveJournal.xcodeproj
   - Enter your OpenAI API key in the API Configuration section
   - Build and run on a simulator or device

### Development Testing

1. Access the "More" tab in the app
2. Select "Enhanced Story Map" for the new visualization
3. Select "Story Map Testing" for the comprehensive testing tool
4. Try different visualization modes and interactions

## Troubleshooting

### Common Issues

- **API Key Issues**: Ensure the key is valid and properly stored
- **Network Errors**: Check server connectivity and API rate limits
- **Visualization Problems**: Reset the view or restart the app if visualization behaves unexpectedly

### Logs and Debugging

- **Server Logs**: Check the terminal running the server for errors
- **iOS Logs**: View the Xcode console for detailed client-side logs
- **Analytics Data**: Review analytics for usage patterns and errors

## Future Improvements

- **Additional Genres**: Expand the available narrative genres
- **Richer Visualizations**: Add more visualization options and interactivity
- **Collaborative Stories**: Allow multiple students to contribute to a shared narrative
- **Audio Narration**: Add text-to-speech capabilities for story reading
- **Animated Transitions**: Improve visual transitions between story nodes
- **Custom Themes**: Allow students to create custom visual themes for their stories
