<p align="center">
  <img src="assets/icons/banner_hero.png" width="100%" alt="SpeechMate — Offline Tribal Language Learning">
</p>

<h1 align="center">SPEECHMATE</h1>

<p align="center">
  <strong>Offline-first language learning for endangered Nicobarese and Great Andamanese languages.</strong><br>
  <em>Built for tribal primary schools in the Andaman &amp; Nicobar Islands.</em>
</p>

<p align="center">
  <a href="#">
    <img src="https://img.shields.io/badge/Stage-Pre--Pilot_Prototype-orange?style=for-the-badge" alt="Pre-Pilot Prototype" />
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/Flutter-3.29+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter 3.29+" />
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/Offline--First-Core_Features-00C853?style=for-the-badge" alt="Offline-First" />
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/Target-Ages_6–14-FF6B6B?style=for-the-badge" alt="Ages 6-14" />
  </a>
</p>

<p align="center">
  <a href="#-the-problem">🌍 Problem</a> •
  <a href="#-core-value">🎯 Core</a> •
  <a href="#-status">📊 Status</a> •
  <a href="#-why-speechmate">⚡ Why Us</a> •
  <a href="#-installation">🚀 Install</a> •
  <a href="#-license">📜 License</a>
</p>

---

## 🌍 The Problem

> *"A Nicobarese child walks into a government school in Car Nicobar. The teacher speaks Hindi. The textbook is in English. The child's mother tongue — spoken by fewer than 30,000 people — has no place in the classroom. By the time she graduates, she may no longer speak it."*

**Car Nicobarese** and **Great Andamanese** are critically endangered. There are **no widely accessible or child-focused digital tools** for learning them. Children in these schools cannot bridge the gap between their mother tongue and the medium of instruction — not because they lack ability, but because offline-first tools tailored for tribal classrooms don't exist.

- A language dies every **14 days** globally.
- The Andaman & Nicobar school system has no tribal-language digital curriculum.
- Remote islands have **unreliable or zero internet connectivity** — cloud-based tools don't work here.

**SpeechMate** is an attempt to build that missing tool. It is a **pre-pilot prototype** — functional, but not yet validated in schools.

---

## 🎯 Core Value

**One sentence:** Offline voice-based Nicobarese vocabulary learning for tribal primary school children and their teachers.

**Two features that matter most:**

| Feature | What it does | Status |
| :--- | :--- | :--- |
| **🎙️ Voice Translation** | Speak in Hindi/Tamil/Bengali/Telugu → hear Nicobarese audio | ✅ Working |
| **📚 Vocabulary Learning** | 12 categories, 2,400+ words, games, flashcards, spaced repetition | ✅ Working |

Everything else in this app supports these two features or is exploratory.

---

## 📊 Status (Honest)

This is a **pre-pilot prototype**. Here is what each feature's status actually is:

| Feature | Status | Notes |
| :--- | :--- | :--- |
| Nicobarese dictionary (2,400+ words) | ✅ **Working** | JSON lexicons, seeded to SQLite |
| Word learning games (4 games) | ✅ **Working** | Match, Flashcards, Scramble, Runner |
| SM-2 Spaced Repetition (SRS) | ✅ **Working** | Standard Anki-style algorithm |
| XP / leveling / daily missions | ✅ **Working** | Deterministic, no backend needed |
| Regional language translation (4 lang) | ✅ **Working** | Google ML Kit offline models |
| On-device STT (Whisper Base) | ✅ **Working** | Via NDK 27 C++ — tested on mid-range Android |
| Teacher dashboard | ✅ **Working** | Phrase bank, quiz mode, OCR scanner |
| AR object → Nicobarese overlay | ⚠️ **Partial** | Works on static images; live video overlay is experimental |
| Malayalam translation | ⚠️ **Partial** | Requires internet (cloud fallback) |
| Great Andamanese hub | ⚠️ **Partial** | Lexicon loaded; voice + OCR functional, community features UI-only |
| Omni-Broadcast (5 languages at once) | 🧪 **Experimental** | Architecture built; latency on low-end devices not validated |
| Dialect heatmap, Culture Hub | 🧪 **Experimental** | UI complete; data is placeholder |
| P2P sync, Document translation | 🧪 **Experimental** | Feature works but no field testing |
| Virtual pet | 🧪 **Experimental** | Functional; pedagogical value untested |

> **Not yet done:** User testing, accuracy benchmarks, school deployment, community audio recordings.

---

## ⚡ Why SpeechMate?

| Feature | Google Translate | Duolingo | Offline Dictionary Apps | SpeechMate |
| :--- | :--- | :--- | :--- | :--- |
| **Tribal Languages** | No Nicobarese support | No Nicobarese support | No tribal languages | ✅ Nicobarese & G. Andamanese |
| **Connectivity** | Requires internet | Requires internet | ✅ Works offline | ✅ Works fully offline* |
| **Target Audience** | General audience | ✅ Child-focused | General audience | ✅ Built for ages 6–14 |
| **Classroom Fit** | Not designed for tribal classrooms | Not designed for tribal classrooms | Not designed for tribal classrooms | ✅ Tailored for tribal classrooms |
| **Educator Tools** | None | Schools edition | None | ✅ Custom teacher dashboard |
| **Voice Learning** | ✅ Supported | ✅ Supported | No voice features | ✅ Supported |

> *\*Core vocabulary and translation is offline. AR overlay and Malayalam use partial online features.*

**The gap is real.** No tool — commercial or academic — currently supports Nicobarese or Great Andamanese language learning for children.

---

## 🏗️ Architecture

```
Flutter UI (Riverpod)
    │
    ├── WhisperService (NDK 27 C++) — On-device speech-to-text
    ├── NeuralEngine — Offline translation pipeline (dictionary + NLP)
    ├── ML Kit — Regional translation + OCR + object detection
    └── DatabaseManager (SQLite) — All linguistic data, locally stored
```

**Translation pipeline (7 meaningful stages):**
Dictionary lookup → Bigram/Trigram phrase match → Stemming → Synonym expansion → Soundex phonetic fallback → Compound word split → Levenshtein fuzzy match.

> No generative AI or cloud LLMs. All translation is deterministic dictionary + algorithmic NLP.

### Technical Specs

| Metric | Value | Notes |
| :--- | :--- | :--- |
| App size | ~250 MB | Includes 141 MB Whisper model |
| STT latency | ~600ms | Tested on a mid-range Android (Snapdragon 6xx). Low-end devices not benchmarked. |
| Translation speed | <100ms | SQLite indexed lookup |
| Dictionary | 2,400+ entries | Core Nicobarese lexicon |
| Min Android | API 24 | Android 7.0+ |

---

## 🛤️ Roadmap

### Phase 1 — Validation (Next)
- [ ] Pilot in 2–3 A&N tribal schools with ~30 students
- [ ] Collect teacher feedback on classroom usability
- [ ] Community recording program with tribal elders
- [ ] Benchmark STT latency on low-end school devices

### Phase 2 — Refinement (Post-Pilot)
- [ ] Lean APK build (<50 MB, Whisper-optional)
- [ ] Validated accuracy metrics for translation
- [ ] Onges language module

### Phase 3 — Scale (Future)
- [ ] Cloud sync for community content
- [ ] On-device LLM for generative practice (SmolLM2 GGUF)
- [ ] Government curriculum integration

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

## 📂 Additional Documentation

| Document | Contents |
| :--- | :--- |
| [`/docs/architecture.md`](docs/architecture.md) | Full system architecture, service layer, Mermaid diagrams |
| [`/docs/features.md`](docs/features.md) | Complete feature list for all modules |
| [`/docs/data.md`](docs/data.md) | Lexicon structure, JSON format, how to add languages |

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
- ✅ **Educational/Research Use:** You may use the data freely for non-commercial research, personal learning, and educational tools with proper attribution.

> **Summary:** You can fork and build upon the app's code freely under Apache 2.0, but the tribal language data is strictly protected under CC BY-NC 4.0 and cannot be exploited for profit.

---

<p align="center">
  Built for the tribal communities of the Andaman &amp; Nicobar Islands.<br>
  <em>Pre-pilot prototype — not yet validated in schools.</em>
</p>
