# SpeechMate — Complete Feature Inventory (v1.6.0 Institutional Edition)

> **Status key:**
> - ✅ Production — fully built, tested, and verified
> - 🔄 Beta — functional with scheduled optimizations
> - 🔜 Roadmap — planned for upcoming school deployment phase
> - 🆕 New in v1.5.0 / v1.6.0

---

## ⌨️ Nicobarese Custom Keyboard (v1.6.0)

Students and teachers can now type Nicobarese natively device-wide.

| Module | Description | Status |
| :--- | :--- | :--- |
| **System-Level IME Keyboard** | Full Android Input Method Service (IME) enabling native Nicobarese typing in any application | 🆕 ✅ |
| **Sovereign Specialized Keys** | Dedicated key layout for language-specific characters: `ä`, `ö`, `ë`, `ṅ`, and glottal stop `·` | 🆕 ✅ |
| **Premium Custom Themes** | 4 selectables: Forest Teal (Explorer), Tribal Coral (Heritage), Midnight Sovereign (Midnight), and Coconut Shell (Organic) | 🆕 ✅ |
| **Interactive Keyboard Sandbox** | Student dashboard widget sandbox allowing live layout practice and theme switching | 🆕 ✅ |
| **One-Tap Settings Launcher** | Integrated dashboard tile allowing students to instantly activate the system IME keyboard | 🆕 ✅ |
| **Tactile Haptic Feedback** | Immersion-enhancing physical vibration feedback on keypresses | 🆕 ✅ |
| **Sovereign Shift/Caps System** | Seamless uppercase support for special characters (`Ä`, `Ö`, `Ë`, `Ṅ`, and `·`) | 🆕 ✅ |

---

## Student Dashboard — Core Learning

| Module | Description | Status |
| :--- | :--- | :--- |
| **Bento Grid Layout** | Modern, glassmorphic student dashboard decomposing the previous monolithic grid into component widgets | 🆕 ✅ |
| **Word Match Game** | Tap the correct Nicobarese word for a shown English equivalent, featuring missed-word re-injection | ✅ |
| **Flash Cards** | Audio + visual flashcard drill with native pronunciation playback | ✅ |
| **Word Scramble** | Gamified letter-unscrambling exercise for spell practice | ✅ |
| **Word Runner** | Timed rapid-identification vocabulary runner | ✅ |
| **SRS Flashcards** | SM-2 Spaced Repetition Algorithm optimizing daily review schedules for students | ✅ |
| **Chat Translator** | Bidirectional translation dialogue using local dictionary context | ✅ |
| **Regional Translators** | Bidirectional: Nicobarese ↔ Hindi, Tamil, Bengali, Telugu, Kannada (100% offline via ML Kit) | 🆕 ✅ |
| **SQLite Session Telemetry** | Session tracking and learning analytics stored fully offline in local SQLite databases | 🆕 ✅ |
| **Classroom Leaderboard** | Real-time classroom XP podium showing student rank | 🆕 ✅ |
| **Achievement Badges** | 20+ unlockable achievement badges celebrating learning milestones | 🆕 ✅ |
| **Cultural Calendar** | Lunar phase aware tribal event calendar with protocol warnings | 🆕 ✅ |
| **Multilingual Search** | Dynamic search auto-translating scripts (Devanagari, Tamil, Bengali) into English before local lookup | ✅ |
| **XP & Leveling** | 11 custom progression levels (Seedling → Sprout → Explorer → Elder) with streak multipliers | ✅ |
| **Daily Missions** | Deterministic daily mission generator based on calendrical seeds | ✅ |
| **Confetti Engine** | Physics-based reward celebrations on streak completions and achievements | ✅ |
| **Voice Vault** | Local recording sandbox allowing students to record oral pronunciations | ✅ |
| **QR offline Sync** | Off-grid progress, stats, and custom word sync via QR matrix generation | ✅ |
| **Feedback System** | Direct vocabulary correction submissions for teacher moderation | ✅ |
| **Whisper STT** | On-device Whisper speech-to-text (Base model compiling via C++ NDK 27 bridge) | ✅ |

---

## Student Dashboard — Advanced Capabilities

| Module | Description | Status |
| :--- | :--- | :--- |
| **AR Translator** | Live camera-based object detection with real-time Nicobarese translation labels | 🔄 |
| **Omni-Broadcast** | Speak a single sentence to trigger offline translation into 5 regional languages simultaneously | 🔄 |
| **Memory Palace** | Gamified spatial vocabulary system mapping words to a simulated virtual A&N village | 🔄 |
| **Dialect Heatmap** | Interactive mapping zone showing geographic distribution of dialect variations | ✅ |
| **Virtual Pet** | Gamified pet companion showing dynamic mood swings and XP-based evolutions | ✅ |
| **Linguistic Kinship Mapper** | Interactive visual diagram mapping Car Nicobarese complex traditional family terms | ✅ |
| **Illustrated Body Parts** | Educational anatomical reference tool with Nicobarese naming guides | ✅ |

---

## Teacher Dashboard

| Module | Description | Status |
| :--- | :--- | :--- |
| **Student Analytics** | Teacher dashboard tracking individual student SRS records, streak states, and levels | ✅ |
| **Lesson Assigning** | Allows teachers to assign vocabulary sets and customize daily classroom missions | ✅ |
| **Dictionary Editor** | In-app dictionary editor permitting teachers/elders to directly add, edit, or remove lexicons | ✅ |
| **Book Scanner (OCR)** | Camera document scanner instantly parsing printed textbooks into local translations | ✅ |
| **Curriculum Pathing** | Teacher curriculum levels (1–10) guiding classrooms through vocab blocks | ✅ |
| **Nature Hub** | Offline flora and fauna identifier with indigenous names and eco-uses | ✅ |
| **Oral History Radio** | Audio archive playing back recorded narratives of community elders | ✅ |
| **kinship Tuhet Mapper** | Dedicated module for teachers to demonstrate traditional land and family structures | ✅ |

---

## Great Andamanese Hub

A specialized standalone module featuring 4 integrated tools for the Aka-Jeru language:

| Tab | Feature | Status |
| :--- | :--- | :--- |
| **Dictionary** | Searchable GA database (1,000+ words) with parts of speech and TTS audio | ✅ |
| **Translator** | English → Great Andamanese exact-match translator with phrase-level fallback | ✅ |
| **Voice** | Whisper-enabled voice-to-text translating spoken English into Great Andamanese | ✅ |
| **OCR Scanner** | Camera-based textbook translation from English into Great Andamanese | ✅ |

---

## ⚡ 100+ Enterprise Native Integrations (v1.5.0)

Integrated across 10 critical systems:
1. **Audio DSP:** Noise Gate, Voice Activity Detection, TD-PSOLA Voice morphing, FFT cadences.
2. **Vision/OCR:** Binarization, Sobel edge detect overlays, ML Kit camera integrations.
3. **AI/Speech:** Whisper GGUF on-device compilation, Phonetics TTS.
4. **Mesh Sync:** Bonjour discovery, CRDT merge engines, local sockets.
5. **Bat-Sync:** Manchester sound modulation, Goertzel bandpass filters.
6. **GIS/Eco:** WGS-84 geodesic projections, Eco-Lux CPU throttling.
7. **Security:** AES-GCM, ChaCha20, TEE system keystore binding.
8. **SIMD Math:** ARM NEON accelerators for fast DSP computations.
9. **Environment:** Coastal Wind compensation filters, Lunar calendars.
10. **Utilities:** SQLite telemetry engines, local servers, collab boards.
