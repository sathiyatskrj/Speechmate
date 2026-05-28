# SpeechMate — Complete Feature List (Institutional Edition v1.5.0)

> **Status key:**
> - ✅ Working — built and manually tested
> - ⚠️ Partial — functional but incomplete or dependent on connectivity
> - 🧪 Experimental — built but not validated; may not work on all devices
> - 🆕 New in v1.5.0

---

## 🏝️ Student Dashboard — Island Journey (v1.5.0)

The student experience has been rebuilt with a 5-zone **Island Journey** layout.

| Zone | Component | Description | Status |
| :--- | :--- | :--- | :--- |
| **Zone 1** | Hero Header | Animated greeting with wave-effect background, XP level badge with pulse animation, daily streak flame counter | 🆕 ✅ |
| **Zone 2** | Island Map Grid | 12 vocabulary categories as interactive island tiles with emoji, animated borders, and tap-ripple effects | 🆕 ✅ |
| **Zone 3** | Activity Strip | Quick-launch horizontal row: Games 🎮, Voice 🎙️, Camera 📸, Quiz ⚡, Spaced Repetition 🧠 | 🆕 ✅ |
| **Zone 4** | Progress Cove | Live XP progress bar with smooth fill animation, star count, and level name from SharedPreferences | 🆕 ✅ |
| **Zone 5** | Discovery Shelf | Horizontal scroll cards: Word of Day, Survival Phrases, Cultural Tips — dynamically generated | 🆕 ✅ |

**New Student Features in v1.5.0:**

| Feature | Description | Status |
| :--- | :--- | :--- |
| **Animated Hero Header** | Wave-effect background, pulsing level badge, live streak display | 🆕 ✅ |
| **12 Island Vocabulary Tiles** | Numbers, Nature, Colors, Feelings, Things, Body Parts, Animals, Magic Words, Family, Phrases, Dialects, GA Hub | 🆕 ✅ |
| **Activity Quick-Launch Strip** | One tap to games, voice, camera, quiz — no deep navigation | 🆕 ✅ |
| **Live XP Progress Bar** | Smooth animated fill, tied to real SharedPreferences XP state | 🆕 ✅ |
| **Word of Day Card** | Deterministic daily Nicobarese word with emoji and translation | 🆕 ✅ |
| **Survival Phrase Cards** | Greetings, Food, Directions, Emergency — horizontally scrollable | 🆕 ✅ |
| **Cultural Tip Cards** | Short contextual tips about Nicobarese culture on the Discovery Shelf | 🆕 ✅ |
| **Confetti Physics** | Particle effects triggered on XP milestone achievements | 🆕 ✅ |

---

## 📋 Teacher Dashboard — Morning Briefing (v1.5.0)

The teacher workspace has been rebuilt as a **4-tab Morning Briefing** professional layout.

| Tab | Name | Features | Status |
| :--- | :--- | :--- | :--- |
| **Tab 1** | 📋 Roster | Real student list, search bar, attendance toggle, per-student profile tap, add/remove students | 🆕 ✅ |
| **Tab 2** | 📝 Marks | Grade entry grid with subject columns (Vocab / Quiz / Speaking), tap-to-edit cells, auto-save | 🆕 ✅ |
| **Tab 3** | 📊 Analytics | Class quiz score trends, class average, individual performance sparklines, top/bottom performers | 🆕 ✅ |
| **Tab 4** | 📅 Calendar | Full CRUD for school events — add, edit, delete events with date picker and description | 🆕 ✅ |

**New Teacher Features in v1.5.0:**

| Feature | Description | Status |
| :--- | :--- | :--- |
| **Morning Briefing Header** | Teacher name, current date, class name, and live student count chip | 🆕 ✅ |
| **Real Roster Management** | Add/remove students persistently via SQLite — survives app restart | 🆕 ✅ |
| **Attendance System** | Tap-to-toggle per-student presence tracking with daily log | 🆕 ✅ |
| **Marks Entry Grid** | Editable tap-to-type grade cells per subject column, auto-saved | 🆕 ✅ |
| **Quiz Analytics** | Class average %, top performer highlight, individual sparkline trend | 🆕 ✅ |
| **School Calendar CRUD** | Create / read / update / delete events with date picker | 🆕 ✅ |
| **Live Search** | Real-time roster filter as teacher types student names | 🆕 ✅ |

---

## Core Student Learning Features

| Feature | Description | Status |
| :--- | :--- | :--- |
| **12 Vocabulary Categories** | Numbers, Nature, Colors, Feelings, Things, Body Parts, Animals, Magic Words, Family, Phrases, Dialects, GA — loaded from Nicobarese JSON lexicons | ✅ |
| **4 Learning Games** | Word Match, Flash Cards, Word Scramble, Word Runner | ✅ |
| **Spaced Repetition (SM-2)** | SM-2 algorithm for long-term flashcard retention | ✅ |
| **Voice Translator** | On-device Whisper Base STT → 10-stage NeuralEngine → Nicobarese output | ✅ |
| **AR Camera Translator** | Camera-based object detection with Nicobarese overlay via ML Kit. 3 lens modes (Auto/Objects/Text) | ⚠️ |
| **Regional Translators** | Bidirectional offline: Nicobarese ↔ Hindi, Tamil, Bengali, Telugu, Kannada (ML Kit) | ✅ |
| **XP & Leveling** | 11 named levels with streak multipliers and daily mission rewards | ✅ |
| **Daily Missions** | Deterministic goal selector refreshed daily | ✅ |
| **Confetti** | Physics particle effects on XP milestones | ✅ |
| **Document Translation** | Offline PDF/TXT parser → Nicobarese | 🧪 |
| **Omni-Broadcast** | Speak once → translate to 5 regional languages simultaneously | 🧪 |

---

## Core Teacher Features

| Feature | Description | Status |
| :--- | :--- | :--- |
| **Classroom Phrase Bank** | Teacher-curated phrase library pushed to student devices | ✅ |
| **Adaptive Quiz Mode** | Generates quizzes from any vocabulary category | ✅ |
| **OCR Book Scanner** | Scan printed textbook pages → auto-add words to lesson plan | ✅ |
| **Dictionary Editor** | Add/edit/delete Nicobarese vocabulary entries locally | ✅ |
| **Student Word Corrections** | Students flag incorrect translations → queued for teacher review | ✅ |
| **P2P Sync** | Export/import vocabulary packs via offline ZIP payloads | ✅ |

---

## Great Andamanese Hub

| Tab | Feature | Status |
| :--- | :--- | :--- |
| **Dictionary** | Searchable GA lexicon (1,000+ entries) with POS filters + TTS | ✅ |
| **Translator** | English → Great Andamanese (exact match + word-by-word fallback) | ✅ |
| **Voice** | Whisper transcription → auto-translation to GA | ✅ |
| **OCR Scanner** | Scan printed English text → translate to GA | ✅ |

---

## Cultural & Discovery Features

| Module | Description | Status |
| :--- | :--- | :--- |
| **Culture Hub** | Indigenous traditions, festivals, folklore, cultural context | ✅ |
| **Dialect Comparison** | Side-by-side view across Car, Central, Coast, Teressa & Chowra dialects | ⚠️ |
| **Voice Vault** | Record and preserve oral history or field recordings locally | ✅ |
| **Flora & Fauna Hub** | Endemic species with Nicobarese names and traditional uses | ✅ |
| **Oral History Radio** | Storytelling archive and oral audio recordings | ✅ |
| **Tuhet Mapper** | Kinship structure visualization for indigenous family trees | ✅ |

---

## System & Performance

| Feature | Description | Status |
| :--- | :--- | :--- |
| **Whisper Base STT** | 141 MB GGUF model, native C++ via NDK 27, with VAD + gibberish filtering | ✅ |
| **10-Stage Translation Pipeline** | Phrase match → bigram → trigram → dictionary → context → stemming → synonym → soundex → compound → fuzzy | ✅ |
| **SQLite Indexed DB** | O(1) dictionary lookup with version-controlled seeding | ✅ |
| **Offline-First Architecture** | Zero cloud dependency, data sovereignty for indigenous languages | ✅ |
| **Core Library Desugaring** | Enabled for `flutter_local_notifications` Java 8+ compat | ✅ |
| **Version** | `1.5.0+10` — pubspec.yaml + build.gradle + dart.yml | ✅ |
