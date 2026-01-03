# Release Notes

## Version 1.4.0 (2026-01-03)

### 🚀 New Features
*   **Restored Teacher Dashboard**: Complete restoration of all teacher-focused tools, ensuring a robust platform for educators. Key features include:
    *   **Daily Word**: Feature to display a new word each day.
    *   **Common Phrases**: Quick access to essential phrases.
    *   **Community Hub**: Area for community interaction (restored).
    *   **Translation**: Full translation capabilities.
    *   **Quiz Mode**: Interactive quizzes for testing knowledge.
    *   **Progress Tracking**: Tools to monitor student or personal progress.
    *   **Word Management**: Features for managing the dictionary content.
    *   **About Section**: Information about the app and team.
*   **Revamped Culture Section**:
    *   **Dedicated Space**: Moved from the Student Dashboard to its own dedicated section for better focus.
    *   **Enhanced UI**: Redesigned to verify alignment with the professional aesthetic of the Teacher Dashboard.
    *   **Rich Content**: Integrated comprehensive cultural information covering Music, Dance, Festivals, Food, and Crafts (sourced from `culture_data.md`).
*   **Student Dashboard Enhancements**:
    *   **Mini-Games**: Added 3 new interactive mini-games focused on Nicobarese-English translation to make learning fun.
    *   **Surprises**: Included hidden easter eggs/surprises to increase student engagement.
*   **Printable Planner**: Added functionality to generate a custom, printable monthly habit planner.

### 🐛 Bug Fixes
*   **Dictionary & Search**:
    *   Resolved the "Word not found" error plaguing the Student Dashboard.
    *   Fixed the unresponsive Search button in the Teacher Dashboard.
    *   Debugged `DictionaryService` to ensure `getRandomWords` and other methods function correctly.
*   **Stability & Build**:
    *   **Android Build**: Fixed critical C++ build failures by downgrading `whisper.cpp` to v1.5.4 and correcting `CMakeLists.txt` configurations for GGML.
    *   **Crash Fixes**: Resolved crashes related to the Speech-to-Text (STT) functionality on Android.
    *   **Code Corrections**: Fixed syntax and compilation errors in `QuizScreen` (missing braces, try-catch blocks) and `ColorsPage`.
    *   **Dependencies**: Added missing `permission_handler` to `pubspec.yaml` to fix permission-related crashes.

### 🛠 Improvements
*   **UI/UX**: General improvements to the visual consistency and responsiveness of the application across different screens.
*   **Performance**: Optimizations to the dictionary data loading and search algorithms for faster results.
*   **Documentation**: Content structure improvements for better maintainability (e.g., separating culture data).
