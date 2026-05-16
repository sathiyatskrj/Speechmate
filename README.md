<p align="center">
  <img src="assets/icons/banner_hero.png" width="100%" alt="SpeechMate — Offline Tribal Language Learning Platform">
</p>

<h1 align="center">SPEECHMATE</h1>

<p align="center">
  <strong>An offline-first vocabulary learning platform for endangered Nicobarese and Great Andamanese languages.</strong><br>
  <em>Purpose-built for tribal primary schools in the Andaman &amp; Nicobar Islands where internet access is unreliable or nonexistent.</em>
</p>

<p align="center">
  <a href="#">
    <img src="https://img.shields.io/badge/Version-1.4.9-blue?style=for-the-badge" alt="Version 1.4.9" />
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/Flutter-3.29+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter 3.29+" />
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/Offline--First-00C853?style=for-the-badge" alt="Offline-First" />
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/Target-Ages_6–14-FF6B6B?style=for-the-badge" alt="Ages 6-14" />
  </a>
</p>

<p align="center">
  <a href="#-the-problem">🌍 Problem</a> •
  <a href="#-what-speechmate-does">🎯 Solution</a> •
  <a href="#-offline-architecture">🏗️ Architecture</a> •
  <a href="#-why-speechmate">⚡ Why Us</a> •
  <a href="#-governance--data-sovereignty">🛡️ Governance</a> •
  <a href="#-sustainability--maintenance">🔄 Sustainability</a> •
  <a href="#-installation">🚀 Install</a>
</p>

---

## 🌍 The Problem

> *"A Nicobarese child walks into a government school in Car Nicobar. The teacher speaks Hindi. The textbook is in English. The child's mother tongue — spoken by fewer than 30,000 people — has no place in the classroom. By the time she graduates, she may no longer speak it."*

**Car Nicobarese** and **Great Andamanese** are critically endangered languages. We could not find any existing child-focused digital learning tools for these languages. Children in tribal schools cannot bridge the gap between their mother tongue and the medium of instruction — not because they lack ability, but because the tools don't exist yet.

- A language dies every **14 days** globally ([UNESCO](https://en.unesco.org/endangeredlanguages)).
- The A&N school system has **no tribal-language digital curriculum**.
- Remote islands have **unreliable or zero internet** — cloud-based tools fail entirely.

SpeechMate is built to address this specific gap: **offline vocabulary learning for Nicobarese in tribal classrooms**.

---

## 🎯 What SpeechMate Does

**Core mission:** Offline voice-based Nicobarese vocabulary learning for tribal primary school children (ages 6–14) and their teachers.

SpeechMate is intentionally focused on **one problem**: helping children learn endangered vocabulary through games, audio, and teacher-guided activities — without requiring internet.

### Student Learning Tools

| Feature | What It Does |
| :--- | :--- |
| **📚 Vocabulary Modules** | 12 categorized word sets (2,400+ entries) with audio pronunciations and emoji cues |
| **🎮 4 Learning Games** | Word Match, Flash Cards, Word Scramble, Word Runner — reinforcement through play |
| **🔁 Spaced Repetition** | SM-2 algorithm for long-term vocabulary retention |
| **🎙️ Voice Input** | On-device speech-to-text (Whisper Base, native C++) for hands-free lookup |
| **🌐 Regional Translation** | Nicobarese ↔ Hindi, Tamil, Bengali, Telugu via on-device ML Kit models |
| **⭐ XP & Progress** | 11 learning levels with streak tracking and daily missions |

### Teacher Tools

| Feature | What It Does |
| :--- | :--- |
| **📝 Classroom Phrases** | Pre-built phrase bank with audio for common classroom interactions |
| **📊 Quiz Mode** | Adaptive vocabulary quiz with missed-word re-injection |
| **📸 Book Scanner** | OCR scanner — point at English text, see Nicobarese translation |
| **✏️ Dictionary Editor** | Teachers/elders can locally edit, correct, or add vocabulary on-device |
| **📈 Progress Dashboards** | Class-level learning analytics and SRS review stats |
| **👥 Class Roster** | Student management with class filtering and performance status |
| **📊 Quiz Analytics** | Priority alerts, class averages, weak word identification |
| **✏️ Marks Entry** | Per-student score input with assessment type selection |

### Great Andamanese Hub

A dedicated module for the Great Andamanese language with 1,000+ searchable dictionary entries, translator, voice input, and OCR scanner.

<details>
<summary><strong>🔬 Additional Capabilities</strong></summary>

These features extend the core learning platform:

| Feature | Description |
| :--- | :--- |
| **AR Object Translator** | Camera-based object detection with Nicobarese overlay |
| **Dialect Comparison** | Side-by-side view across 5 Nicobarese dialect regions |
| **Document Translation** | Offline PDF/TXT parser → Nicobarese output |
| **QR Sync** | Offline peer-to-peer vocabulary and progress sharing |
| **Voice Vault** | Record and preserve oral history audio locally |

</details>

---

## 🏗️ Offline Architecture

### What Runs On-Device (No Internet Required)

| Component | Technology | Connectivity |
| :--- | :--- | :--- |
| Speech-to-text | Whisper Base (C++ via NDK 27) | ✅ Fully offline — model bundled in APK |
| Nicobarese translation | 10-stage dictionary + NLP pipeline | ✅ Fully offline — SQLite database |
| Hindi/Tamil/Bengali/Telugu translation | Google ML Kit | ✅ Offline after one-time model download (~30 MB per language) |
| OCR text scanning | Google ML Kit Text Recognition | ✅ Offline after one-time model download |
| Object detection (AR) | Google ML Kit | ✅ Offline after one-time model download |
| Malayalam translation | Cloud translator package | 🌐 **Requires internet** |
| All vocabulary & audio | Local JSON + SQLite + bundled MP3 | ✅ Fully offline |

> **Important:** ML Kit language models require a one-time download on first use (requires temporary internet or can be pre-loaded via sideloading). After download, they operate fully offline. Malayalam is the only feature that requires persistent internet access.

### Technical Specifications

| Spec | Value | Notes |
| :--- | :--- | :--- |
| APK size | **~80 MB** | Whisper model downloaded on first launch (~141 MB) |
| Total on-device | ~220 MB | After Whisper + ML Kit downloads |
| STT latency | ~600ms | Benchmarked on Snapdragon 6xx (mid-range) |
| Translation speed | <100ms | SQLite indexed lookup |
| Min Android | API 24 (Android 7.0+) | |
| Framework | Flutter 3.29+ · Dart 3.2+ | |

> **On APK size:** v1.4.9 moves the Whisper model to on-demand download, reducing the APK from ~250 MB to ~80 MB. The model is downloaded automatically on first launch via the Asset Download Screen.

> See [`/docs/architecture.md`](docs/architecture.md) for the full translation pipeline and system diagram.

---

## ⚡ Why SpeechMate?

| Capability | Google Translate | Duolingo | Offline Dict Apps | **SpeechMate** |
| :--- | :--- | :--- | :--- | :--- |
| **Nicobarese / G. Andamanese** | ❌ Not supported | ❌ Not supported | ❌ Not available | ✅ 2,400+ and 1,000+ entries |
| **Offline Operation** | ❌ Requires internet | ❌ Requires internet | ✅ Offline | ✅ Offline-first (see details above) |
| **Child-Focused (ages 6–14)** | ❌ General audience | ✅ Gamified | ❌ General audience | ✅ Games, XP, daily missions |
| **Classroom Tools** | ❌ None | ⚠️ Schools edition | ❌ None | ✅ Teacher + Student dashboards |
| **On-Device Voice** | ✅ Cloud-based | ✅ Cloud-based | ❌ None | ✅ On-device Whisper STT |
| **Indigenous Data Sovereignty** | ❌ Cloud-processed | ❌ Cloud-processed | ⚠️ Varies | ✅ All data stays on device |

> To our knowledge, no existing commercial or academic tool supports Nicobarese or Great Andamanese vocabulary learning for children. If you know of one, please [open an issue](https://github.com/sathiyatskrj/Speechmate/issues) — we want to collaborate, not compete.

---

## 📐 Pedagogical Approach

SpeechMate's learning methodology draws from established second-language acquisition research:

| Method | Implementation | Research Basis |
| :--- | :--- | :--- |
| **Spaced Repetition** | SM-2 flashcard algorithm | Pimsleur (1967), Leitner system — proven for vocabulary retention |
| **Gamified Practice** | XP, levels, daily missions, 4 game types | Deterding et al. (2011) — gamification in education |
| **Multi-Modal Input** | Audio + visual + text + emoji cues | Mayer's Multimedia Learning Theory (2001) |
| **Active Recall** | Quiz mode with missed-word re-injection | Roediger & Karpicke (2006) — testing effect |
| **Teacher-Mediated Learning** | Dedicated teacher dashboard + progress tracking | Vygotsky's Zone of Proximal Development |

> **Note:** These pedagogical methods are well-established in language learning research. SpeechMate implements them for the specific context of endangered tribal languages in offline environments. Formal classroom outcome studies are planned for the pilot phase — see [Roadmap](#-roadmap).

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

SpeechMate is built with the principle that **indigenous language data belongs to indigenous communities**, not to the developers or any organization.

| Governance Principle | Implementation |
| :--- | :--- |
| **Community consent** | Formal tribal council engagement planned before any school deployment |
| **Data ownership** | All linguistic data stays on-device; no cloud collection |
| **Correction authority** | In-app Dictionary Editor allows teachers and elders to modify entries |
| **Non-extractive** | CC BY-NC 4.0 prevents commercial exploitation of language data |
| **Transparent sourcing** | All academic references documented in [`LINGUISTIC_SOURCES.md`](docs/LINGUISTIC_SOURCES.md) |

> **Current status:** The linguistic dataset is compiled from published academic sources (see [sources](docs/LINGUISTIC_SOURCES.md)). Formal partnerships with tribal councils, CIIL Mysuru, and community elders are actively being pursued for the pilot phase. No deployment will occur without appropriate community consent.

> See [`DATA_TERMS.txt`](DATA_TERMS.txt) for the complete data usage terms.

---

## 🔄 Sustainability & Maintenance

| Concern | How SpeechMate Addresses It |
| :--- | :--- |
| **Who updates vocabulary?** | In-app Dictionary Editor allows teachers and elders to add, correct, or modify entries directly on-device — no developer intervention needed |
| **Who records audio?** | Voice Vault module enables community members to record and preserve audio locally. Community recording sessions planned for pilot phase |
| **What happens after funding?** | Core app requires zero server infrastructure — no ongoing hosting costs. The offline-first architecture eliminates recurring cloud expenses |
| **How are app updates delivered?** | APK sideloading for schools without internet; standard Play Store for connected users |
| **Who maintains the code?** | Open-source under Apache 2.0 — community contributions welcome. Modular architecture allows independent feature updates |
| **Is there institutional continuity?** | Pursuing formal engagement with A&N Tribal Welfare Department and CIIL Mysuru for long-term institutional support |

> **Key advantage of offline-first:** SpeechMate has **zero recurring infrastructure costs** for core operation. No servers, no APIs, no subscriptions. The app works indefinitely on any installed device without ongoing maintenance.

---

## 🛤️ Roadmap

| Phase | Focus | Key Milestones |
| :--- | :--- | :--- |
| **Current** | Core platform | 2,400+ word vocabulary, 4 games, teacher dashboard, STT, OCR, regional translation |
| **Phase 2 — Pilot** | Classroom validation | School deployment in A&N, teacher feedback collection, learning outcome measurement, tribal council engagement, APK size optimization (<100 MB) |
| **Phase 3 — Scale** | Expansion | Community recording program, additional language modules (Onges), curriculum integration, institutional partnerships |

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
  Built for the tribal communities of the Andaman &amp; Nicobar Islands.
</p>
