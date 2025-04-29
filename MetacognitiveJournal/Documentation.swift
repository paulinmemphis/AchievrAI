import Foundation

/**
 # Metacognitive Journal App
 
 ## Overview
 The Metacognitive Journal App is an educational tool that combines journaling with AI-powered narrative generation
 to help students develop metacognitive skills through creative storytelling.
 
 ## Key Components
 
 ### Core Features
 1. **Journal Entry System**
    - `JournalEntryView`: Displays individual journal entries
    - `AIJournalEntryView`: Multi-step journal entry creation with AI-powered insights
 
 2. **Narrative Co-Creation Engine**
    - `NarrativeAPIService`: Handles communication with the narrative engine server
    - `GenreSelectionView`: Allows students to select genres for their stories
    - `ChapterView`: Displays generated story chapters with personalized feedback
 
 3. **Story Visualization**
    - `StoryMapView`: Visual representation of the student's story journey
    - `StoryReadingView`: Full story reading experience
    - `StoryMetadataInsightsView`: Analytics and insights about the story
 
 4. **Data Management**
    - `StoryPersistenceManager`: Manages storage and retrieval of story nodes and arcs
    - `SecretManager`: Securely stores sensitive API keys
    - `AnalyticsManager`: Tracks user engagement patterns
 
 ### Architecture
 
 The app follows a modified MVVM architecture with the following layers:
 
 1. **Model Layer**
    - Data structures in `NarrativeDataModels.swift`
    - Persistence in `StoryPersistenceManager.swift`
 
 2. **View Layer**
    - SwiftUI views for user interface
    - Sheet-based navigation for multi-step workflows
 
 3. **ViewModel Layer**
    - Services like `NarrativeAPIService` for business logic
    - Manager classes for cross-cutting concerns
 
 4. **Server Layer**
    - Node.js server for narrative generation using OpenAI's GPT models
    - RESTful API endpoints for metadata extraction and chapter generation
 
 ## Key Workflows
 
 ### Narrative Generation Flow
 1. Student creates a journal entry in `AIJournalEntryView`
 2. Student selects a genre using `GenreSelectionView`
 3. `NarrativeAPIService` extracts metadata from the journal content
 4. `NarrativeAPIService` generates a personalized chapter based on metadata and genre
 5. `ChapterView` displays the generated chapter with feedback
 6. `StoryPersistenceManager` saves the story node and creates a story arc
 
 ### Error Handling and Offline Support
 1. `NetworkErrorManager` detects offline status
 2. Requests are queued for later processing
 3. UI displays offline notification with retry option
 4. When connection is restored, pending requests are processed
 
 ## Best Practices
 
 ### API Key Security
 - OpenAI API keys are stored securely in the iOS Keychain using `SecretManager`
 - Keys are never hardcoded in the source code
 - Server uses request-scoped API keys for maximum flexibility
 
 ### Performance Optimization
 - Server implements caching with `node-cache` to reduce API calls
 - App implements local caching for network responses
 - Rate limiting prevents abuse of the OpenAI API
 
 ### Narrative Continuity
 - `StoryArc` objects track the narrative flow across chapters
 - Recent story arcs are included in generation requests for continuity
 - Analytics track which narrative elements resonate most with students
 
 ## Testing Strategy
 
 1. **Unit Tests**
    - `NarrativeAPIServiceTests`: Tests API communication
    - `StoryPersistenceManagerTests`: Tests story storage and retrieval
 
 2. **Integration Tests**
    - End-to-end tests for the narrative generation flow
 
 3. **UI Tests**
    - Tests for key user interactions
 */
