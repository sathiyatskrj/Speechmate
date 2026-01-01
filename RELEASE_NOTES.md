# Release Notes - SpeechMate v1.4.5 (Scientific Update)

**"Learning Awakens."**

This update brings a massive overhaul to the user experience, introducing **Scientific Engines** to make the app feel alive, responsive, and rewarding. We have also fully gamified the Teacher Certification path.

## 🧬 Feature Highlights

### 1. Scientific UI Overhaul 🧪
We introduced three distinct animation engines to create a high-fidelity experience:
*   **Biology Engine (Teacher Levels)**: The certification path is now a living **Neural Network**. Levels ("neurons") pulse and breathe organically, connected by a biological pathway.
*   **Physics Engine (Learning)**: Interactive elements now possess **weight and springiness**. Cards bounce (`elasticOut`), progress bars fill like fluid, and buttons respond tactilily.
*   **Chemistry Engine (Rewards)**: Correct answers trigger a **chemical reaction** (confetti explosion), providing instant, satisfying feedback.

### 2. Gamified Teacher Certification 🎮
*   **Interactive Path**: A visual journey replacing the old list.
*   **Learn & Quiz Loop**: Each level now follows a pedagogical "Learn -> Quiz" flow.
    *   **Learn**: Study the word and listen to pronunciation.
    *   **Quiz**: Test your knowledge with immediate feedback.
*   **Audio Integration**: Words now play audio files with a TTS fallback.

### 3. Smart Search & Dashboard 🔍
*   **Inline Search**: The Student Dashboard search is now faster, cleaner, and displays results inline without context switching.

## 🛠️ Technical Improvements
*   **Split APKs**: Reduced download size by generating architecture-specific APKs (ARM64, ARMv7).
*   **Asset Fix**: Resolved audio path issues for "Magic Words".

---

# Release Notes - SpeechMate v1.0.0 (Hackathon Edition)

**"Where Language Barriers End."**

We are thrilled to announce the first major release of **SpeechMate**, an offline-first educational platform designed to preserve **endangered tribal languages**. While this release launches with **Nicobarese**, the architecture is built to scale to any indigenous language.

## 🚀 Key Features
*   **🎙️ Offline Voice Search (Edge AI)**: Integrated **OpenAI Whisper (C++)** for instant, accurate English-to-Nicobarese voice translation without internet.
*   **🏫 Teacher Dashboard**: A dedicated admin panel for teachers to manage the "Daily Word", view curriculum resources, and access the "Voice Vault".
*   **👧 Student Fairyland**: A gamified student interface with "Magic Words", "Animals", "Family", and more, designed to make learning engaging.
*   **🌍 100% Offline Capability**: Built for remote areas (Andaman & Nicobar Islands) with zero dependency on cloud APIs.
*   **🧩 Mini-Games**: Interactive quizzes and word runners to reinforce vocabulary.
*   **⚡ Optimized Performance**: 
    *   App size reduced via ABI splitting (~35MB per APK).
    *   Background thread processing for zero-lag AI inference.
    *   Battery-efficient native C++ integration.

## 🐛 Bug Fixes & Improvements
*   **Build System**: Fixed Gradle build failures and dependency conflicts (`flutter_native_splash`, AGP versions).
*   **AI Engine**: Resolved UI freezing issues during voice recognition by implementing background isolate threading.
*   **Audio Pipeline**: Fixed audio recording parameters (16kHz PCM16) to strictly match Whisper model requirements.
*   **Search Logic**: Fixed dictionary loading errors and improved search resilience (case-insensitivity, "No match" feedback).
*   **UI/UX**: Enhanced button responsiveness in Teacher Dashboard and fixed empty "Daily Word" displays.

## 🔮 Known Limitations (Beta)
*   Voice input is currently optimized for English-to-Nicobarese only.
*   TTS (Text-to-Speech) uses system default engines; native Nicobarese pronunciation is approximated.

---
*Built with ❤️ for the Smart India Hackathon.*
