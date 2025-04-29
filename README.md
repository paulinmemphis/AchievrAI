# Metacognitive Journal App

## Overview

Metacognitive Journal is a SwiftUI-based iOS application designed to help users enhance self-awareness and emotional understanding through guided journaling. It incorporates features like text and voice entries, emotional analysis, and gamification to encourage consistent reflection and personal growth. The app also includes a parent dashboard feature for monitoring usage and insights.

## Key Features

*   **Journaling:** Create text-based journal entries or respond to thoughtful prompts.
*   **Voice Journaling:** Record thoughts using voice, with automatic transcription.
*   **Emotional Analysis:** Basic analysis of journal entries to identify emotional tone (via `MetacognitiveAnalyzer`).
*   **Progress & Gamification:**
    *   Earn points for journaling.
    *   Level up based on accumulated points.
    *   Track daily journaling streaks.
    *   Unlock badges for achievements (e.g., first entry, streaks, reaching levels).
    *   Persistent state saved across app sessions.
    *   Visual progress displayed in the "Progress" tab with smooth animations.
*   **Parent Dashboard:** A PIN-protected area for parents/guardians to view usage statistics and potentially high-level insights (requires setup).
*   **Themes:** Customizable app appearance with different themes.
*   **Mascot:** A simple mascot character reflects the mood derived from the latest journal entry.

## Getting Started

### Prerequisites

*   macOS with Xcode installed (latest version recommended).
*   An iOS Simulator or a physical iOS device.

### Building and Running

1.  Clone or download the repository.
2.  Navigate to the project directory:
    ```bash
    cd /Users/paul/Documents/AchievrAI/MetacognitiveJournal
    ```
3.  Open the `MetacognitiveJournal.xcodeproj` file in Xcode.
4.  Select a target simulator or connect a device.
5.  Click the "Run" button (or press `Cmd+R`) in Xcode.

## Architecture Overview

*   **UI Framework:** SwiftUI
*   **Architecture Pattern:** Primarily MVVM-inspired, utilizing `@StateObject`, `@ObservedObject`, and `@EnvironmentObject` for state management.
*   **Core Components:**
    *   `JournalStore`: Manages the storage, retrieval, and modification of journal entries (persisted using `UserDefaults` or a similar mechanism).
    *   `GamificationManager`: Handles points, levels, streaks, badges, and persistence for gamification features.
    *   `MetacognitiveAnalyzer`: Provides basic analysis of entry text (currently placeholder/simple implementation).
    *   `ParentalControlManager`: Manages PIN access and settings for the Parent Dashboard.
    *   `ThemeManager`: Manages the application's visual theme.
    *   `VoiceJournalViewModel`: Manages state and logic for the voice recording and transcription feature.
*   **Data Persistence:** `UserDefaults` is used for storing journal entries, gamification state, settings, and PIN information.

## Future Enhancements

*   More sophisticated Metacognitive Analysis.
*   Wider variety of badges, goals, and quests.
*   Enhanced visual feedback and animations for gamification milestones.
*   Cloud synchronization (e.g., iCloud) for journal entries and progress.
*   More detailed insights and trends in the Parent Dashboard.
*   Refined UI/UX across all sections.

## Contributing

(Placeholder: Add contribution guidelines if the project becomes open source or collaborative).

## License

(Placeholder: Add license information, e.g., MIT License).
