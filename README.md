<p align="center">
  <img src="assets/icons/banner_hero.png" width="100%" alt="SpeechMate — Andaman & Nicobar Institutional Language Platform">
</p>

<h1 align="center">SPEECHMATE: Institutional Edition v1.5.0</h1>

<p align="center">
  <strong>India's first offline-first language learning and classroom management platform for endangered Nicobarese and Great Andamanese languages.</strong><br>
  <em>Built for teachers and students in tribal primary schools across the Andaman &amp; Nicobar Islands.</em>
</p>

<p align="center">
  <a href="#">
    <img src="https://img.shields.io/badge/v1.5.0-Institutional_Edition-6A0DAD?style=for-the-badge" alt="Institutional Edition v1.5.0" />
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/Flutter-3.29+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter 3.29+" />
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/Offline--First-100%25_Native-00C853?style=for-the-badge" alt="Offline-First" />
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/Target-Teachers_%26_Students-FF6B6B?style=for-the-badge" alt="Teachers & Students" />
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/Dashboards-Island_Journey_%26_Morning_Briefing-8A2BE2?style=for-the-badge" alt="New Dashboards" />
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/Keyboard-Custom_Nicobarese-teal?style=for-the-badge" alt="Custom Keyboard" />
  </a>
</p>

<p align="center">
  <a href="#-the-mission">🌍 Mission</a> •
  <a href="#-whats-new-in-v150">🆕 v1.5.0</a> •
  <a href="#-student-dashboard--island-journey">🏝️ Student Dash</a> •
  <a href="#-teacher-dashboard--morning-briefing">📋 Teacher Dash</a> •
  <a href="#-core-features">✨ Features</a> •
  <a href="#-architecture">🏗️ Architecture</a> •
  <a href="#-installation">🚀 Install</a> •
  <a href="#-branch-structure">🗂️ Branches</a> •
  <a href="#-licensing">📜 License</a>
</p>

---

## 🌍 The Mission

> *"A tribal primary school teacher in Car Nicobar has 30 students, no reliable internet, and a single mobile device. She needs tools to teach Nicobarese vocabulary, track each child's progress, and run quizzes — all offline."*

The Andaman & Nicobar Islands are home to critically endangered indigenous languages like **Car Nicobarese** and **Aka-Jeru (Great Andamanese)**. These languages have **no modern digital learning tools** tailored for classroom use.

SpeechMate (Institutional Edition) bridges this gap:

- 📵 **Zero connectivity needed** — works entirely offline in remote island schools.
- 🧑‍🏫 **Teacher-centric design** — real classroom roster, marks entry, quiz analytics, and phrase banks.
- 🎒 **Student-centric design** — gamified Island Journey with XP, streaks, and 12 learning categories.
- 🧠 **Deterministic NLP** — no cloud AI; all translation runs on-device, protecting data sovereignty.

---

## 🆕 What's New in v1.5.0

### 🏝️ Student Dashboard — Island Journey Redesign

The student experience has been completely rebuilt with an **Island Journey** metaphor — a 5-zone immersive layout replacing the old flat card grid.

| Zone | Component | Description |
| :--- | :--- | :--- |
| **Zone 1** | Hero Header | Animated greeting, current XP level badge, daily streak flame counter |
| **Zone 2** | Island Map Grid | 12 vocabulary categories as interactive island tiles with emoji & animated borders |
| **Zone 3** | Activity Strip | Quick-launch row: Games 🎮, Voice 🎙️, Camera 📸, Quiz ⚡ |
| **Zone 4** | Progress Cove | XP progress bar, star count, level name — live from SharedPreferences |
| **Zone 5** | Discovery Shelf | Horizontal scroll: Word of Day, Survival Phrases, Cultural Tip cards |

**New Student Features:**
- 🌅 **Animated hero header** with wave-effect background and pulse badge for level
- 🗺️ **Island tile grid** — 12 categories (Numbers, Nature, Colors, Feelings, Things, Body Parts, Animals, Magic Words, Family, Phrases, Dialects, Great Andamanese) with hover animations
- 📊 **Live XP progress bar** with smooth fill animations
- 🃏 **Horizontal discovery cards** — dynamically generated word-of-day, phrase cards, and cultural tips
- 🎮 **Activity quick-launch strip** — one tap to voice translator, 4 learning games, AR camera, quiz
- ✨ **Confetti physics** on XP milestone achievements

### 📋 Teacher Dashboard — Morning Briefing Redesign

The teacher interface has been rebuilt with a **Morning Briefing** layout — a 4-tab professional workspace replacing the legacy tabbed design.

| Tab | Name | Features |
| :--- | :--- | :--- |
| **Tab 1** | 📋 Roster | Real student list with attendance toggle, search bar, per-student profile tap |
| **Tab 2** | 📝 Marks | Grade entry grid with subject columns, auto-save to local SQLite |
| **Tab 3** | 📊 Analytics | Live quiz performance charts, class average, individual progress sparklines |
| **Tab 4** | 📅 Calendar | Stateful event CRUD — add/edit/delete school events with date picker |

**New Teacher Features:**
- 🌄 **Morning Briefing header** with teacher name, date, and class summary chip
- 👥 **Real roster management** — add/remove students, persistent across app restarts
- ✅ **Attendance system** with tap-to-toggle per-student presence tracking
- 📝 **Marks entry** — tap-to-edit grade cells with subject-wise columns
- 📊 **Analytics tab** — class quiz score trends, highest/lowest performers, subject breakdown
- 📅 **School calendar** — full CRUD for events (assemblies, exam days, cultural festivals)
- 🔍 **Search bar** across roster with live filtering
- 💾 **All data persists offline** — SQLite-backed, no sync required

### 🔧 Other v1.5.0 Changes

| Change | Details |
| :--- | :--- |
| **Version bump** | `1.5.0+10` across pubspec.yaml, build.gradle, and CI workflow |
| **Android workflow** | Updated `dart.yml` to v1.5.0 build matrix |
| **Build stability** | Core library desugaring enabled for `flutter_local_notifications` |
| **Crash fixes** | Student dash layout crash, phrasebook padding error resolved |

---

## 🏝️ Student Dashboard — Island Journey

The Student Dashboard uses a **5-zone island metaphor** to make vocabulary learning feel like an adventure:

```
┌─────────────────────────────────────────┐
│  Zone 1: HERO HEADER                    │
│  👋 Good Morning, [Name]!               │
│  🔥 12-day streak  •  ⭐ 340 XP  •  🏆 Level 5 │
├─────────────────────────────────────────┤
│  Zone 2: ISLAND MAP GRID (4×3)          │
│  🔢 Numbers  🌿 Nature  🎨 Colors       │
│  💭 Feelings  📦 Things  🫀 Body Parts  │
│  🐾 Animals  ✨ Magic   👨‍👩‍👧 Family    │
│  📖 Phrases  🗣️ Dialects  🌀 GA Hub    │
├─────────────────────────────────────────┤
│  Zone 3: ACTIVITY STRIP                 │
│  🎮 Games  🎙️ Voice  📸 Camera  ⚡ Quiz │
├─────────────────────────────────────────┤
│  Zone 4: PROGRESS COVE                  │
│  XP ████████░░  Level: Island Explorer  │
├─────────────────────────────────────────┤
│  Zone 5: DISCOVERY SHELF (horizontal)   │
│  [Word of Day] [Phrase Card] [Tip Card] │
└─────────────────────────────────────────┘
```

---

## 📋 Teacher Dashboard — Morning Briefing

The Teacher Dashboard presents a **professional 4-tab workspace**:

```
┌─────────────────────────────────────────┐
│  🌄 Morning Briefing — Ms. Sumitha      │
│  Wednesday, 28 May · Class 4B · 28 pupils│
│  [📋 Roster] [📝 Marks] [📊 Analytics] [📅 Calendar] │
├─────────────────────────────────────────┤
│  Tab 1: ROSTER                          │
│  🔍 Search students...                  │
│  ○ Arjun K.     ✅ Present              │
│  ○ Meena R.     ❌ Absent               │
│  [+ Add Student]                        │
├─────────────────────────────────────────┤
│  Tab 2: MARKS                           │
│  Name       | Vocab | Quiz | Speaking   │
│  Arjun K.   |  85   |  72  |   90       │
│  Meena R.   |  78   |  81  |   88       │
├─────────────────────────────────────────┤
│  Tab 3: ANALYTICS                       │
│  Class Avg: 82% • Top: Arjun K. (92%)  │
│  [📈 Quiz trend sparkline chart]        │
├─────────────────────────────────────────┤
│  Tab 4: CALENDAR                        │
│  📅 29 May — Unit Test: Numbers         │
│  📅 2 Jun  — Cultural Day Celebration   │
│  [+ Add Event]                          │
└─────────────────────────────────────────┘
```

---

## ✨ Core Features

### For Students

| Feature | Description | Status |
| :--- | :--- | :--- |
| **Island Journey Dashboard** | 5-zone gamified home screen with XP, streak, and exploration | 🆕 ✅ |
| **12 Vocabulary Categories** | Numbers, Nature, Colors, Feelings, Things, Body Parts, Animals, Magic Words, Family, Phrases, Dialects, GA | ✅ |
| **4 Learning Games** | Word Match, Flash Cards, Word Scramble, Word Runner | ✅ |
| **Spaced Repetition (SM-2)** | Long-term retention algorithm for flashcards | ✅ |
| **Voice Translator** | On-device Whisper STT → 10-stage NeuralEngine → Nicobarese | ✅ |
| **Camera (AR) Translator** | Point-and-scan text/objects → Nicobarese via ML Kit | ⚠️ |
| **XP & Leveling** | 11 named levels, streak multipliers, confetti milestones | ✅ |
| **Daily Missions** | Deterministic goal selector refreshed daily | ✅ |
| **Offline STT** | Whisper Base on-device via NDK 27 C++ bridge | ✅ |
| **Regional Translation** | Offline ML Kit: Hindi, Tamil, Bengali, Telugu, Kannada | ✅ |
| **Great Andamanese Hub** | 1,000+ lexicon, translator, voice, OCR scanner | ✅ |

### For Teachers

| Feature | Description | Status |
| :--- | :--- | :--- |
| **Morning Briefing Dashboard** | 4-tab professional classroom workspace | 🆕 ✅ |
| **Real Roster Management** | Add/remove students, persistent SQLite storage | 🆕 ✅ |
| **Attendance Tracking** | Per-student tap-to-toggle presence with daily log | 🆕 ✅ |
| **Marks Entry** | Editable grade grid with subject columns, auto-save | 🆕 ✅ |
| **Quiz Analytics** | Class average, top/bottom performers, trend charts | 🆕 ✅ |
| **School Calendar CRUD** | Add/edit/delete events with date picker | 🆕 ✅ |
| **Classroom Phrase Bank** | Teacher-curated phrases pushed to student devices | ✅ |
| **Adaptive Quiz Mode** | Generates quizzes from vocabulary categories | ✅ |
| **OCR Book Scanner** | Scan physical textbooks → add words to lesson plans | ✅ |
| **Dictionary Editor** | Add/edit Nicobarese vocabulary entries locally | ✅ |

---

## 🏗️ Architecture

```
Flutter UI (Riverpod)
    │
    ├── StudentDash (Island Journey — 5 zones)
    │       ├── HeroHeader — XP, streak, level badge
    │       ├── IslandMapGrid — 12 category tiles
    │       ├── ActivityStrip — quick-launch actions
    │       ├── ProgressCove — XP bar, stars, level
    │       └── DiscoveryShelf — word of day, phrase cards
    │
    ├── TeacherDash (Morning Briefing — 4 tabs)
    │       ├── RosterTab — student list, attendance
    │       ├── MarksTab — grade entry grid
    │       ├── AnalyticsTab — performance charts
    │       └── CalendarTab — event CRUD
    │
    ├── NativeEdgeService (Dart FFI → C++ NDK 27)
    │       ├── Audio DSP (VAD, PCM, Mel, PSOLA)
    │       ├── CRDT Mesh Sync & XOR Encryption
    │       ├── GIS Geofencing & WGS-84 Math
    │       └── ARM NEON SIMD Accelerators
    │
    ├── WhisperService (NDK 27 C++) — On-device STT
    ├── NeuralEngine — 10-stage offline translation pipeline
    ├── ML Kit (Hindi, Tamil, Bengali, Telugu, Kannada) — Offline
    ├── GamificationService — XP, missions, levels
    ├── ProgressService — SharedPreferences state
    └── DatabaseManager (SQLite) — All data, locally stored
```

> No generative AI or cloud LLMs. All translation is deterministic dictionary + algorithmic NLP — zero data privacy leaks.

### Technical Specs

| Metric | Value | Notes |
| :--- | :--- | :--- |
| APK size | **~80 MB** | Whisper model downloaded post-install (~141 MB) |
| Total on-device | ~220 MB | After Whisper download |
| STT latency | ~600ms | Tested on mid-range Android (Snapdragon 6xx) |
| Translation speed | <100ms | SQLite indexed lookup |
| Min Android | API 24 | Android 7.0+ |
| Build version | `1.5.0+10` | pubspec.yaml + build.gradle |
| NDK | 27 | Required for Whisper C++ bridge |

---

## 🚀 Installation

```bash
# 1. Clone the Institutional (main) branch
git clone -b main https://github.com/sathiyatskrj/Speechmate.git
cd Speechmate

# 2. Install dependencies
flutter pub get

# 3. Pull Whisper model (Git LFS — 141 MB)
git lfs pull

# 4. Run
flutter run
```

**Requirements:** Flutter 3.29+ · Dart 3.2+ · Android NDK 27 · Android SDK 34

---

## 🗂️ Branch Structure

| Branch | Edition | Audience | Key Features |
| :--- | :--- | :--- | :--- |
| `main` | **Institutional Edition** | Teachers & Students | Island Journey student dash, Morning Briefing teacher dash, classroom management, gamification, progress tracking |
| `speechmate_general` | Explorer Edition | Travelers, General Public | 100+ native integrations, Nicobarese keyboard, off-grid tools, explorer bento dashboard |

---

## 📜 Licensing

SpeechMate uses a **split-licensing model** to keep the source code open while strictly protecting indigenous data sovereignty.

### 1. Software Code: Apache 2.0
All source code in this repository is licensed under the [Apache License 2.0](LICENSE). You are free to use, modify, and distribute the software for commercial and non-commercial purposes.

### 2. Linguistic Data: CC BY-NC 4.0
All dictionary entries, audio recordings, and cultural content (located in `assets/data/` and `assets/audio/`) are licensed under **Creative Commons Attribution-NonCommercial 4.0 (CC BY-NC 4.0)**, combined with Traditional Knowledge (TK) protocols. See [DATA_TERMS.txt](DATA_TERMS.txt) for details.

**Key rules for the data:**
- 🚫 **No Commercial Use:** You may not sell, monetize, or use the data in commercial products without written consent from the relevant tribal council.
- 🚫 **No AI Training:** You may not use this data to train commercial AI or LLMs.
- ✅ **Educational Use:** You may use the data freely for non-commercial research, classroom teaching, and respectful educational tools with proper attribution.

---

<p align="center">
  Preserving endangered languages of the Andaman &amp; Nicobar Islands — one classroom at a time.<br>
  <em>100% offline · 100% on-device · built for tribal schools</em>
</p>
