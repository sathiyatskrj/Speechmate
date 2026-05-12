<p align="center">
  <img src="assets/icons/banner_hero.png" width="100%" alt="SpeechMate — Offline Tribal Language Learning Platform">
</p>

<h1 align="center">SPEECHMATE</h1>

<p align="center">
  <strong>India's first offline-first language learning platform for endangered Nicobarese and Great Andamanese languages.</strong><br>
  <em>Purpose-built for tribal primary schools in the Andaman &amp; Nicobar Islands.</em>
</p>

<p align="center">
  <a href="#">
    <img src="https://img.shields.io/badge/Version-1.4.8-blue?style=for-the-badge" alt="Version 1.4.8" />
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/Flutter-3.29+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter 3.29+" />
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/100%25-Offline--First-00C853?style=for-the-badge" alt="100% Offline-First" />
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/Target-Ages_6–14-FF6B6B?style=for-the-badge" alt="Ages 6-14" />
  </a>
</p>

<p align="center">
  <a href="#-the-problem">🌍 Problem</a> •
  <a href="#-what-speechmate-does">🎯 Solution</a> •
  <a href="#-platform-metrics">📊 Metrics</a> •
  <a href="#-why-speechmate">⚡ Why Us</a> •
  <a href="#-data-sovereignty--ip">🛡️ IP</a> •
  <a href="#-installation">🚀 Install</a> •
  <a href="#-licensing">📜 License</a>
</p>

---

## 🌍 The Problem

> *"A Nicobarese child walks into a government school in Car Nicobar. The teacher speaks Hindi. The textbook is in English. The child's mother tongue — spoken by fewer than 30,000 people — has no place in the classroom. By the time she graduates, she may no longer speak it."*

**Car Nicobarese** and **Great Andamanese** are critically endangered languages with **zero child-focused digital learning tools**. Children in tribal schools cannot bridge the gap between their mother tongue and the medium of instruction — not because they lack ability, but because the tools don't exist.

- A language dies every **14 days** globally.
- The A&N school system has **no tribal-language digital curriculum**.
- Remote islands have **unreliable or zero internet connectivity** — cloud-based tools fail entirely.

**SpeechMate** fills this gap with a fully offline, classroom-ready language learning platform.

---

## 🎯 What SpeechMate Does

**One sentence:** Offline voice-based Nicobarese vocabulary learning for tribal primary school children and their teachers.

### Core Production Features

| Feature | What It Does |
| :--- | :--- |
| **🎙️ Voice Translation** | Speak in Hindi/Tamil/Bengali/Telugu → hear Nicobarese translation with audio |
| **📚 Vocabulary Learning** | 12 categorized modules with 2,400+ words, audio pronunciations, and emoji cues |
| **🎮 4 Learning Games** | Word Match, Flash Cards, Word Scramble, Word Runner — reinforcement through play |
| **🔁 Spaced Repetition (SRS)** | SM-2 algorithm for long-term vocabulary retention |
| **🏫 Teacher Dashboard** | Classroom phrase bank, adaptive quiz mode, OCR book scanner, dictionary editor |
| **🌐 Regional Translation** | Bidirectional: Nicobarese ↔ Hindi, Tamil, Bengali, Telugu — fully offline via ML Kit |
| **🗣️ On-Device STT** | Whisper Base via native C++ (NDK 27) — no cloud dependency |
| **📸 Camera Translation** | Scan printed text (signs, textbooks) → translate to Nicobarese via ML Kit OCR |

### Great Andamanese Hub

| Feature | What It Does |
| :--- | :--- |
| **📖 GA Dictionary** | Searchable lexicon (1,000+ entries) with part-of-speech filters and TTS |
| **🔄 GA Translator** | English → Great Andamanese with exact match + word-by-word fallback |
| **🎙️ GA Voice** | Whisper transcription → auto-translation to Great Andamanese |
| **📸 GA OCR Scanner** | Scan printed English text → translate to Great Andamanese |

### Engagement System

| Feature | What It Does |
| :--- | :--- |
| **⭐ XP & Leveling** | 11 named levels (Seedling → Elder) with streak multipliers |
| **📋 Daily Missions** | Deterministic daily goals — no backend required |
| **📊 Progress Analytics** | Class-level tracking and SRS dashboards |
| **🔗 QR Sync** | Offline peer-to-peer vocabulary and progress sharing via QR codes |

<details>
<summary><strong>🔬 Advanced Capabilities</strong></summary>

| Feature | Description |
| :--- | :--- |
| **AR Object Translator** | Camera-based object detection with Nicobarese overlay (3 lens modes) |
| **Omni-Broadcast** | Speak once → translate to 5 regional languages simultaneously |
| **Dialect Comparison** | Side-by-side view across Car, Central, Coast, Teressa & Chowra dialects |
| **Document Translation** | Offline PDF/TXT parser → Nicobarese output |
| **P2P Sync** | Export/import vocabulary packs via offline ZIP payloads |
| **Voice Vault** | Record and preserve oral history or folklore audio locally |
| **5-Dialect Heatmap** | Interactive A&N map showing dialect distribution zones |

</details>

<details>
<summary><strong>🛤️ Roadmap (Planned)</strong></summary>

| Feature | Timeline |
| :--- | :--- |
| Lean APK build (<100 MB with on-demand model download) | Phase 2 |
| Structured lesson curriculum (Levels 1–10) | Phase 2 |
| Community recording program with tribal elders | Phase 2 |
| Cloud sync for community content | Phase 3 |
| On-device LLM for generative practice (SmolLM2 GGUF) | Phase 3 |
| Government curriculum integration | Phase 3 |
| Onges language module | Phase 3 |

</details>

---

## 📊 Platform Metrics

| Metric | Value |
| :--- | :--- |
| **Nicobarese Vocabulary** | 2,400+ curated entries with audio across 12 categories |
| **Great Andamanese Vocabulary** | 1,000+ searchable entries with POS tagging |
| **Dialect Coverage** | 5 Nicobarese dialects (Car, Central, Coast, Teressa, Chowra) |
| **Regional Languages Supported** | Hindi, Tamil, Bengali, Telugu (offline) · Malayalam (online) |
| **On-Device STT Latency** | ~600ms (benchmarked on Snapdragon 6xx) |
| **Translation Response Time** | <100ms (SQLite indexed lookup) |
| **NLP Pipeline** | 10-stage deterministic translation — zero cloud dependency |
| **Learning Games** | 4 interactive vocabulary reinforcement games |
| **Privacy** | 100% on-device — voice recordings never leave the phone |

---

## ⚡ Why SpeechMate?

| Capability | Google Translate | Duolingo | Offline Dict Apps | **SpeechMate** |
| :--- | :--- | :--- | :--- | :--- |
| **Tribal Languages** | ❌ No Nicobarese | ❌ No Nicobarese | ❌ No tribal languages | ✅ Nicobarese & G. Andamanese |
| **Offline Operation** | ❌ Requires internet | ❌ Requires internet | ✅ Offline | ✅ **100% offline-first** |
| **Child-Focused** | ❌ General audience | ✅ Gamified | ❌ General audience | ✅ **Built for ages 6–14** |
| **Classroom Integration** | ❌ None | ⚠️ School edition | ❌ None | ✅ **Teacher + Student dashboards** |
| **Voice Learning** | ✅ Supported | ✅ Supported | ❌ None | ✅ **On-device Whisper STT** |
| **Data Sovereignty** | ❌ Cloud-processed | ❌ Cloud-processed | ⚠️ Varies | ✅ **All data stays on device** |

> **The gap is real.** No tool — commercial or academic — currently supports Nicobarese or Great Andamanese language learning for children.

---

## 🏗️ Architecture

```
Flutter UI (Riverpod State Management)
    │
    ├── WhisperService (NDK 27 C++) — On-device speech-to-text
    ├── NeuralEngine — 10-stage offline translation pipeline
    ├── ML Kit — Regional translation + OCR + object detection
    └── DatabaseManager (SQLite) — All linguistic data, locally stored
```

> **Design philosophy:** No generative AI. No cloud LLMs. All translation is deterministic dictionary + algorithmic NLP — ensuring zero data privacy leaks and full offline operation.

### Technical Specifications

| Spec | Value |
| :--- | :--- |
| App size | ~250 MB (includes 141 MB Whisper model) |
| STT latency | ~600ms (Snapdragon 6xx) |
| Translation speed | <100ms |
| Min Android | API 24 (Android 7.0+) |
| Framework | Flutter 3.29+ · Dart 3.2+ |
| Native layer | Android NDK 27 (C++ Whisper inference) |

> See [`/docs/architecture.md`](docs/architecture.md) for the full system architecture and translation pipeline details.

---

## 🛡️ Data Sovereignty & IP

SpeechMate uses a **split-licensing model** specifically designed for indigenous language projects:

| Layer | License | Protection |
| :--- | :--- | :--- |
| **Application Code** | Apache 2.0 | Open source — community contribution encouraged |
| **Linguistic Data** | CC BY-NC 4.0 + TK Protocols | Strictly protected indigenous knowledge |

**What this means:**

- ✅ Anyone can contribute to the codebase
- 🚫 Linguistic data **cannot** be used commercially without tribal council consent
- 🚫 Data **cannot** be used to train commercial AI or LLMs
- ✅ Free for education, research, and language preservation

**Our defensibility is not the code — it's the curated linguistic dataset, community relationships, and deployment capability in one of India's most remote regions.**

> See [`DATA_TERMS.txt`](DATA_TERMS.txt) for the complete data usage terms and [`docs/LINGUISTIC_SOURCES.md`](docs/LINGUISTIC_SOURCES.md) for academic source documentation.

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

## 📂 Documentation

| Document | Contents |
| :--- | :--- |
| [`/docs/architecture.md`](docs/architecture.md) | System architecture, service layer, translation pipeline |
| [`/docs/features.md`](docs/features.md) | Complete feature inventory with status |
| [`/docs/data.md`](docs/data.md) | Lexicon structure, JSON format, language-agnostic design |
| [`/docs/LINGUISTIC_SOURCES.md`](docs/LINGUISTIC_SOURCES.md) | Academic sources, references, validation methodology |

---

## 📜 Licensing

### 1. Software Code: Apache 2.0
All source code in this repository is licensed under the [Apache License 2.0](LICENSE). You are free to use, modify, and distribute the software for commercial and non-commercial purposes.

### 2. Linguistic Data: CC BY-NC 4.0
All dictionary entries, audio recordings, and cultural content (located in `assets/data/` and `assets/audio/`) are licensed under **Creative Commons Attribution-NonCommercial 4.0 (CC BY-NC 4.0)**, combined with Traditional Knowledge (TK) protocols. See [DATA_TERMS.txt](DATA_TERMS.txt) for details.

**Key rules for the data:**
- 🚫 **No Commercial Use:** You may not sell, monetize, or use the data in commercial products without written consent from the relevant tribal council.
- 🚫 **No AI Training:** You may not use this data to train commercial AI or LLMs.
- ✅ **Educational/Research Use:** Free for non-commercial research, personal learning, and educational tools with proper attribution.

---

<p align="center">
  Built for the tribal communities of the Andaman &amp; Nicobar Islands.<br>
  <em>Bridging endangered languages and the digital classroom.</em>
</p>
