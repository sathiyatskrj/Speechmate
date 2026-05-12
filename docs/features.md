# SpeechMate — Feature Inventory

> **Status key:**
> - ✅ Production — built, tested, and functional
> - 🔄 Beta — functional with known limitations noted inline
> - 🔜 Roadmap — planned for future release

---

## Student Dashboard — Core Learning

| Module | Description | Status |
| :--- | :--- | :--- |
| **12 Learning Categories** | Numbers, Nature, Feelings, Colors, Things, Body Parts, Animals, Magic Words, Family, and more — loaded from Nicobarese JSON lexicons | ✅ |
| **Word Match Game** | Tap the correct Nicobarese word for a shown image | ✅ |
| **Flash Cards** | Audio + image flashcard drill with pronunciation playback | ✅ |
| **Word Scramble** | Unscramble Nicobarese letters to form words | ✅ |
| **Word Runner** | Timed word identification game for speed practice | ✅ |
| **SRS Flashcards** | SM-2 spaced repetition algorithm for long-term retention | ✅ |
| **Chat Translator** | Conversational translation via offline dictionary + 10-stage NLP pipeline | ✅ |
| **Regional Translators** | Bidirectional: Nicobarese ↔ Hindi, Tamil, Bengali, Telugu (offline via ML Kit) | ✅ |
| **Malayalam Translation** | Nicobarese ↔ Malayalam via cloud translator | 🔄 Online required |
| **Multilingual Search** | Type in any regional language script — auto-translates to English before Nicobarese lookup | ✅ |
| **XP & Leveling** | 11 named levels (Seedling → Elder) with streak multipliers | ✅ |
| **Daily Missions** | Deterministic daily goal selector — no backend required | ✅ |
| **Confetti System** | Physics-based particle effects on achievements | ✅ |
| **Voice Vault** | Record and preserve oral history or folklore audio locally | ✅ |
| **QR Sync** | Offline peer-to-peer vocabulary and progress sync via QR codes | ✅ |
| **Feedback System** | Users submit linguistic corrections for elder/teacher review | ✅ |
| **Whisper STT** | On-device speech-to-text (Whisper Base, native C++ via NDK 27). ~600ms latency on mid-range Android | ✅ |

---

## Student Dashboard — Advanced Capabilities

| Module | Description | Status |
| :--- | :--- | :--- |
| **AR Translator** | Camera-based object detection with Nicobarese overlay via ML Kit. 3 lens modes (Auto/Objects/Text) | 🔄 Static image mode stable; live video in beta |
| **Omni-Broadcast** | Speak once → translate to 5 regional languages simultaneously | 🔄 Architecture complete; optimizing for low-end devices |
| **Memory Palace** | Spatial vocabulary learning linked to a virtual indigenous village map | 🔄 Interface built |
| **Structured Lessons** | Curriculum paths (Levels 1–10) | 🔜 Phase 2 |
| **Dialect Heatmap** | Interactive A&N map showing dialect distribution zones | 🔄 Interface built |
| **Culture Hub** | Indigenous traditions, folklore, cultural context | 🔜 Phase 2 — content pipeline in progress |
| **Community Hub** | Shared learning feed for peer interaction | 🔜 Phase 2 |
| **8-Language UI** | Interface localized in Nicobarese, Great Andamanese, English, Hindi, Tamil, Malayalam, Telugu, Bengali | 🔄 Partial localization complete |
| **Virtual Pet** | Tamagotchi-style companion with mood states, XP-driven evolution, interactive behaviors | 🔄 Functional engagement module |

---

## Teacher Dashboard

| Module | Description | Status |
| :--- | :--- | :--- |
| **Common Phrases** | Pre-built classroom phrase bank with audio playback | ✅ |
| **Voice Search** | Whisper-powered voice-to-search for vocabulary lookup | ✅ |
| **Quiz Mode** | Adaptive vocabulary quiz with missed-word re-injection | ✅ |
| **Book Scanner (OCR)** | ML Kit camera scanner to translate printed English text to Nicobarese | ✅ |
| **Dictionary Editor** | Teachers/elders can locally edit, correct, or add vocabulary on-device | ✅ |
| **Progress Analytics** | Class-level progress tracking and SRS dashboards | ✅ |
| **Certification Levels** | 10 structured proficiency levels with unlock progression | 🔄 Level framework built |
| **Dialect Comparison** | Side-by-side view across Car, Central, Coast, Teressa & Chowra dialects | 🔄 |
| **Document Translation** | Offline PDF/TXT parser → Nicobarese | ✅ |
| **P2P Sync** | Export/import vocabulary packs via offline ZIP payloads | ✅ |
| **Nature Hub** | Flora & fauna database with indigenous names and traditional uses | 🔜 Phase 2 — data collection pipeline |
| **Oral History Radio** | Tribal storytelling archive with playback interface | 🔜 Phase 2 — community recording sessions planned |
| **Tuhet Mapper** | Kinship structure visualization for indigenous family trees | 🔜 Phase 2 |
| **Voice Translator** | Real-time multilingual voice translation | 🔄 |

---

## Great Andamanese Hub

A standalone module with 4 integrated tools:

| Tab | Feature | Status |
| :--- | :--- | :--- |
| **Dictionary** | Searchable GA lexicon (1,000+ entries) with POS filters + TTS | ✅ |
| **Translator** | English → Great Andamanese (exact match + word-by-word fallback) | ✅ |
| **Voice** | Whisper transcription → auto-translation to GA | ✅ |
| **OCR Scanner** | Scan printed English text → translate to GA | ✅ |

---

## Gamification & Engagement Engines

| Engine | Description | Status |
| :--- | :--- | :--- |
| XP & Leveling | 11 named levels with streak multipliers | ✅ |
| Daily Missions | Deterministic daily goal selector | ✅ |
| Confetti | Physics-based particle effects | ✅ |
| Quick Stats | Live streak, stars, level from SharedPreferences | ✅ |
| Virtual Pet | Mood states, XP evolution, interactive speech bubbles | 🔄 |
| Voice Waveform | Animated audio visualizer | ✅ |
