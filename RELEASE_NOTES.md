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
