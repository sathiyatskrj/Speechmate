<p align="center">
  <img src="assets/icons/banner_hero.png" width="100%" alt="SpeechMate — Andaman & Nicobar Islands Language Learning">
</p>

<h1 align="center">SPEECHMATE: Institutional Edition v1.6.0</h1>

<p align="center">
  <strong>The complete offline classroom platform for Nicobarese & Great Andamanese language education.</strong><br>
  <em>Built for teachers, students, and tribal schools bridging ancient languages with modern pedagogy.</em>
</p>

<p align="center">
  <a href="#">
    <img src="https://img.shields.io/badge/v1.6.0-Institutional_Edition-6A0DAD?style=for-the-badge" alt="Institutional Edition v1.6.0" />
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/Flutter-3.29+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter 3.29+" />
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/Offline--First-Classroom_Ready-00C853?style=for-the-badge" alt="Offline-First" />
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/Audience-Teachers_%26_Students-4A90D9?style=for-the-badge" alt="Teachers & Students" />
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/Keyboard-Custom_Nicobarese-teal?style=for-the-badge" alt="Custom Keyboard" />
  </a>
</p>

<p align="center">
  <a href="#-the-problem">🌍 Problem</a> •
  <a href="#-core-value">🎯 Core</a> •
  <a href="#-features">📚 Features</a> •
  <a href="#-nicobarese-custom-keyboard">⌨️ Keyboard</a> •
  <a href="#-architecture">🏗️ Architecture</a> •
  <a href="#-installation">🚀 Install</a> •
  <a href="#-license">📜 License</a>
</p>

---

## 🌍 The Problem

> *"Children in the Andaman & Nicobar Islands grow up hearing Nicobarese and Great Andamanese — two critically endangered languages with no standardized educational tools. Without digital classroom support, these ancient languages are disappearing at an accelerating rate."*

The Andaman & Nicobar Islands are home to critically endangered indigenous languages like **Car Nicobarese** and **Aka-Jeru (Great Andamanese)**. With zero offline-capable educational platforms, the tribal school system has no modern tools to teach or preserve these languages.

**SpeechMate (Institutional Edition)** provides a complete offline classroom ecosystem — from gamified student dashboards to teacher progress monitoring — designed specifically for schools operating in areas with little or no internet connectivity.

---

## 🎯 Core Value

**One sentence:** A complete offline language learning classroom platform for teachers and students of endangered Andaman & Nicobar tribal languages.

**Two features that matter most:**

| Feature | What it does | Status |
| :--- | :--- | :--- |
| **🧑‍🏫 Teacher Dashboard** | Assign lessons, monitor progress, manage dictionary entries, and run classroom sessions | ✅ Working |
| **🎮 Gamified Student Learning** | XP, levels, daily missions, spaced repetition flashcards, and 4+ games | ✅ Working |

---

## 📚 Features

### Student Dashboard

| Feature | Description | Status |
| :--- | :--- | :--- |
| **AR Translator** | Live camera object detection with tribal language overlays | ✅ Working |
| **Voice Vault** | Record, preserve, and play back native speaker audio | ✅ Working |
| **Book Scanner** | OCR camera scan of documents and signs for offline translation | ✅ Working |
| **Games Hub** | Word Match, Memory, Quiz, and more gamified vocabulary exercises | ✅ Working |
| **Classroom Leaderboard** | Live XP-ranked class standings for competitive motivation | ✅ Working |
| **Achievement Badges** | Unlockable milestone badges for streaks, mastery, and exploration | ✅ Working |
| **Cultural Calendar** | Sacred tribal event calendar with etiquette alerts | ✅ Working |
| **Chat Translator** | Bidirectional conversational translation for all supported languages | ✅ Working |
| **Voice Translator** | Speak in any regional language; receive Nicobarese audio output | ✅ Working |
| **Regional Translators** | Hindi, Tamil, Bengali, Telugu, Kannada — all offline via ML Kit | ✅ Working |
| **Tribal Dictionary** | 2,400+ Nicobarese and 1,000+ Great Andamanese vocabulary entries | ✅ Working |
| **Great Andamanese Hub** | Dedicated learning hub for Aka-Jeru (Great Andamanese) language | ✅ Working |
| **Flashcard Review (SRS)** | SM-2 spaced repetition algorithm for optimized vocabulary retention | ✅ Working |
| **Memory Palace** | Spatial memory technique for abstract word retention | ✅ Working |
| **Dialect Heatmap** | Visualize geographic spread of dialects across island regions | ✅ Working |
| **Story Radio** | Oral history recordings and tribal narratives in native languages | ✅ Working |
| **Kinship Mapper** | Interactive visual map of tribal family relationship terms | ✅ Working |
| **Body Parts Screen** | Illustrated vocabulary guide for anatomical terms | ✅ Working |
| **AI Setup Screen** | Configure on-device Whisper STT model and AI preferences | ✅ Working |
| **System Keyboard ⚙️** | One-tap launcher to activate the Nicobarese system keyboard | ✅ Working |
| **Test Custom Keyboard ⌨️** | In-app interactive themed Nicobarese keyboard sandbox | ✅ Working |

### Teacher Dashboard

| Feature | Description | Status |
| :--- | :--- | :--- |
| **Student Progress Tracking** | Monitor individual XP, level, streaks, and mastery per student | ✅ Working |
| **Lesson Management** | Assign vocabulary categories, set daily missions, schedule reviews | ✅ Working |
| **Dictionary Editor** | Add, correct, or modify vocabulary entries directly on-device | ✅ Working |
| **Teacher Levels Screen** | Curriculum level management and progression mapping | ✅ Working |
| **Classroom Analytics** | Aggregate class performance, weak category identification | ✅ Working |

### 🆕 New in v1.5.0 — Student Dashboard Decomposition & Platform Hardening

| Feature | Description |
| :--- | :--- |
| **Dashboard Decomposition** | Monolithic `StudentDash` reduced by 69% into focused widget components |
| **Local NLU Engine** | Genuine dictionary-backed translation replacing all hardcoded LLM stubs |
| **SQLite Analytics** | Offline session telemetry — feature usage, travel data, learning patterns |
| **Premium Onboarding** | Glassmorphic 4-slide interactive first-launch introduction |
| **AOT/FFI Safety** | `try-finally` error boundaries, `dispose` hooks, `@pragma` compiler guards |
| **Native 25 Integrations** | C/C++/Java/Kotlin native bindings across 4 key platform subsystems |
| **Leaderboard** | Live classroom XP ranking with animated podium display |
| **Achievement Badges** | Unlockable milestone system with 20+ badge types |
| **Cultural Calendar** | Tribal etiquette event calendar with lunar phase awareness |

### 🆕 New in v1.6.0 — Authentic Nicobarese Custom Keyboard

| Feature | Description |
| :--- | :--- |
| **System-Level IME Keyboard** | Authentic Nicobarese QWERTY keyboard usable device-wide as default input |
| **Specialized Sovereign Keys** | Dedicated keys for `ä`, `ö`, `ë`, `ṅ`, and glottal stop `·` |
| **4 Premium Visual Themes** | Forest Teal, Tribal Coral, Midnight Sovereign, Coconut Shell |
| **In-App Keyboard Widget** | Interactive keyboard inside the app with live theme switching |
| **One-Tap Settings Launcher** | Dashboard tile opens Android Language & Input Settings instantly |
| **Haptic Feedback** | Tactile key press responses for immersive typing |
| **Full Shift Support** | Uppercase and lowercase for all standard and specialized characters |

---

## ⌨️ Nicobarese Custom Keyboard

SpeechMate ships a **first-of-its-kind authentic Nicobarese QWERTY keyboard** — available both inside the app and as a **system-level Android Input Method (IME)** device-wide. Students can type Nicobarese characters in any app on their device.

### Sovereign Character Keys

```
[ ä ]  [ ö ]  [ ë ]  [ ṅ ]  [ · ]   ← Dedicated top row
[ q ]  [ w ]  [ e ]  [ r ]  [ t ]  [ y ]  [ u ]  [ i ]  [ o ]  [ p ]
[ a ]  [ s ]  [ d ]  [ f ]  [ g ]  [ h ]  [ j ]  [ k ]  [ l ]
[⇧]  [ z ]  [ x ]  [ c ]  [ v ]  [ b ]  [ n ]  [ m ]  [⌫]
[123] [,] [     Space     ] [.] [↵]
```

### 4 Premium Visual Themes

| Theme | Colors | Mood |
| :--- | :--- | :--- |
| 🌲 **Forest Teal** | Deep teal `#0C1D24` / Teal accent | Explorer |
| 🏺 **Tribal Coral** | Terracotta `#2C1916` / Orange accent | Cultural |
| 🌌 **Midnight Sovereign** | Charcoal `#080C14` / Amber accent | Premium |
| 🥥 **Coconut Shell** | Organic brown `#251F1C` / Sand accent | Natural |

### How to Enable for Students

1. Tap the **"System Keyboard ⚙️"** tile on the Student Dashboard
2. The Android **Language & Input Settings** opens instantly
3. Enable **"SpeechMate Keyboard"** from the list
4. Set as default — now active everywhere on the device!

---

## ⚡ Why SpeechMate?

| Capability | Google Translate | Duolingo | Offline Dict Apps | **SpeechMate** |
| :--- | :--- | :--- | :--- | :--- |
| **Nicobarese / G. Andamanese** | ❌ Not supported | ❌ Not supported | ❌ Not available | ✅ 2,400+ and 1,000+ entries |
| **Offline Operation** | ❌ Requires internet | ❌ Requires internet | ✅ Offline | ✅ Offline-first |
| **Child-Focused (ages 6–14)** | ❌ General audience | ✅ Gamified | ❌ General audience | ✅ Games, XP, daily missions |
| **Classroom Tools** | ❌ None | ⚠️ Schools edition | ❌ None | ✅ Teacher + Student dashboards |
| **On-Device Voice** | ✅ Cloud-based | ✅ Cloud-based | ❌ None | ✅ On-device Whisper STT |
| **Indigenous Data Sovereignty** | ❌ Cloud-processed | ❌ Cloud-processed | ⚠️ Varies | ✅ All data stays on device |
| **Custom Nicobarese Keyboard** | ❌ None | ❌ None | ❌ None | ✅ Full IME with 4 themes |

> To our knowledge, no existing commercial or academic tool supports Nicobarese or Great Andamanese vocabulary learning for children. If you know of one, please [open an issue](https://github.com/sathiyatskrj/Speechmate/issues) — we want to collaborate, not compete.

---

## 📐 Pedagogical Approach

SpeechMate's learning methodology draws from established second-language acquisition research:

| Method | Implementation | Research Basis |
| :--- | :--- | :--- |
| **Spaced Repetition** | SM-2 flashcard algorithm | Pimsleur (1967), Leitner system |
| **Gamified Practice** | XP, levels, daily missions, 4 game types | Deterding et al. (2011) |
| **Multi-Modal Input** | Audio + visual + text + emoji cues | Mayer's Multimedia Learning Theory (2001) |
| **Active Recall** | Quiz mode with missed-word re-injection | Roediger & Karpicke (2006) |
| **Teacher-Mediated Learning** | Dedicated teacher dashboard + progress tracking | Vygotsky's Zone of Proximal Development |
| **Authentic Script Practice** | Custom Nicobarese IME keyboard for real typing | Immersive language acquisition |

---

## 🏗️ Architecture

```
Flutter UI (Riverpod)
    │
    ├── TeacherDash — Lesson management, progress monitoring, analytics
    ├── StudentDash (Decomposed Components)
    │       ├── GamificationHeader — XP bar, level, streak
    │       ├── SmartDashboardHeader — Daily word, greeting
    │       ├── BentoGrid — 35+ feature tiles with premium animations
    │       └── SearchableDashboardMixin — Live full-text search
    │
    ├── NativeEdgeService (Dart FFI → C++ NDK 27)
    │       └── Audio DSP, GIS, Security, SIMD integrations
    │
    ├── LocalLlmService — Dictionary-backed adaptive learning path NLU
    ├── WhisperService (NDK 27 C++) — On-device speech-to-text
    ├── ML Kit (Kannada, Hindi, Tamil, Bengali, Telugu) — Offline translation
    ├── NicobareseInputMethodService — System-level IME keyboard (com.speechmate.edu)
    ├── SQLiteAnalytics — Offline telemetry & session tracking
    └── DatabaseManager (SQLite) — All linguistic data, locally stored
```

### Technical Specifications

| Spec | Value | Notes |
| :--- | :--- | :--- |
| APK size | **~80 MB** | Whisper model downloaded on first launch (~141 MB) |
| Total on-device | ~220 MB | After Whisper + ML Kit downloads |
| STT latency | ~600ms | Benchmarked on Snapdragon 6xx (mid-range) |
| Translation speed | <100ms | SQLite indexed lookup |
| Min Android | API 24 (Android 7.0+) | |
| Framework | Flutter 3.29+ · Dart 3.2+ | |

---

## 🛡️ Governance & Data Sovereignty

### Licensing Model

SpeechMate uses a **split-licensing model** specifically designed for indigenous language projects:

| Layer | License | Protection |
| :--- | :--- | :--- |
| **Application Code** | Apache 2.0 | Open source — community contribution encouraged |
| **Linguistic Data** | CC BY-NC 4.0 + TK Protocols | Protected indigenous knowledge |

- 🚫 Linguistic data **cannot** be used commercially without tribal council consent
- 🚫 Data **cannot** be used to train commercial AI or LLMs
- ✅ Free for education, research, and language preservation

### Tribal Governance Commitment

| Governance Principle | Implementation |
| :--- | :--- |
| **Community consent** | Formal tribal council engagement planned before any school deployment |
| **Data ownership** | All linguistic data stays on-device; no cloud collection |
| **Correction authority** | In-app Dictionary Editor allows teachers and elders to modify entries |
| **Non-extractive** | CC BY-NC 4.0 prevents commercial exploitation of language data |
| **Transparent sourcing** | All academic references documented in [`LINGUISTIC_SOURCES.md`](docs/LINGUISTIC_SOURCES.md) |

---

## 🛤️ Roadmap

| Phase | Focus | Key Milestones |
| :--- | :--- | :--- |
| **Current (v1.6.0)** | Custom keyboard + platform hardening | Nicobarese IME, 100+ native integrations, decomposed dashboard, SQLite analytics |
| **Phase 2 — Pilot** | Classroom validation | School deployment in A&N, teacher feedback, learning outcome measurement, tribal council engagement |
| **Phase 3 — Scale** | Expansion | Community recording program, Onge language module, curriculum integration, institutional partnerships |

---

## 🚀 Installation

```bash
# 1. Clone
git clone https://github.com/sathiyatskrj/Speechmate.git
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
| `main` | Institutional Edition | Teachers & Students | Classroom dashboards, gamification, progress tracking, custom keyboard |
| `speechmate_general` | Explorer Edition | Travelers, General Public | 100+ native integrations, Nicobarese keyboard, off-grid tools |

---

## 📂 Documentation

| Document | Contents |
| :--- | :--- |
| [`/docs/architecture.md`](docs/architecture.md) | System architecture, service layer, translation pipeline |
| [`/docs/features.md`](docs/features.md) | Complete feature inventory |
| [`/docs/data.md`](docs/data.md) | Lexicon structure, JSON format, language-agnostic design |
| [`/docs/LINGUISTIC_SOURCES.md`](docs/LINGUISTIC_SOURCES.md) | Academic sources, references, validation methodology |

---

## 📜 Licensing

### 1. Software Code: Apache 2.0
All source code is licensed under the [Apache License 2.0](LICENSE).

### 2. Linguistic Data: CC BY-NC 4.0
All dictionary entries, audio recordings, and cultural content are licensed under **CC BY-NC 4.0** with Traditional Knowledge (TK) protocols. See [DATA_TERMS.txt](DATA_TERMS.txt).

- 🚫 **No Commercial Use** without tribal council consent
- 🚫 **No AI Training** on this data
- ✅ **Educational/Research Use** with proper attribution

---

<p align="center">
  Built for the tribal communities of the Andaman &amp; Nicobar Islands.<br>
  <em>100% offline · 100% on-device · 100% for the community</em>
</p>
