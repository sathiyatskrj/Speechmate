<p align="center">
  <img src="assets/icons/banner_hero.png" width="100%" alt="SpeechMate — Andaman & Nicobar Translation Hub">
</p>

<h1 align="center">SPEECHMATE: General Public & Tourism Edition</h1>

<p align="center">
  <strong>The ultimate offline language and culture companion for the Andaman &amp; Nicobar Islands.</strong><br>
  <em>Built for travelers, researchers, and language enthusiasts bridging the communication gap.</em>
</p>

<p align="center">
  <a href="#">
    <img src="https://img.shields.io/badge/Stage-General_Public_Prototype-blue?style=for-the-badge" alt="General Public Prototype" />
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/Flutter-3.29+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter 3.29+" />
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/Offline--First-Core_Features-00C853?style=for-the-badge" alt="Offline-First" />
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/Target-Tourists_%26_General_Public-FF6B6B?style=for-the-badge" alt="Tourists & Public" />
  </a>
</p>

<p align="center">
  <a href="#-the-problem">🌍 Problem</a> •
  <a href="#-core-value">🎯 Core</a> •
  <a href="#-features-for-travelers">🧳 Features</a> •
  <a href="#-why-speechmate">⚡ Why Us</a> •
  <a href="#-installation">🚀 Install</a> •
  <a href="#-license">📜 License</a>
</p>

---

## 🌍 The Problem

> *"A traveler arrives in the remote islands of the Andaman and Nicobar archipelago. Between the indigenous communities speaking Nicobarese or Great Andamanese, and the local settlers speaking Hindi, Tamil, Bengali, or Malayalam, the language barrier is immense. With virtually zero internet connectivity on these remote islands, cloud-based translators are useless."*

The Andaman & Nicobar Islands are a melting pot of languages and cultures, including critically endangered indigenous languages like **Car Nicobarese** and **Aka-Jeru (Great Andamanese)**. 

Currently, there are **no digital tools** that allow tourists, anthropologists, or general citizens to effectively bridge this gap offline.

- The islands have **unreliable or zero internet connectivity** — standard apps like Google Translate fail entirely for niche regional and tribal languages.
- Visitors lose out on deep **cultural immersion** because they cannot communicate with the locals.
- Endangered languages remain inaccessible to the wider public, accelerating their decline.

**SpeechMate (General Edition)** is built to solve this. It provides a robust, offline-first translation hub tailored specifically for the linguistic landscape of the Andaman & Nicobar Islands.

---

## 🎯 Core Value

**One sentence:** An offline, voice-enabled translation and cultural immersion hub for anyone visiting or interacting with the Andaman & Nicobar Islands.

**Two features that matter most:**

| Feature | What it does | Status |
| :--- | :--- | :--- |
| **🎙️ Omni-Lingual Translation** | Speak in English/Hindi/Tamil/Bengali/Telugu/Malayalam → translate to local languages | ✅ Working |
| **📸 AR & OCR Scanning** | Point your camera at signs or documents to translate them instantly offline | ✅ Working |

Everything else in this app is designed to help users explore, understand, and respect the local culture.

---

## 🧳 Features for Travelers & The Public

This edition strips away the classroom elements of the core app and focuses entirely on real-world utility for the general public:

| Feature | Use Case for Tourists | Status |
| :--- | :--- | :--- |
| **Regional Translators** | Translate Hindi, Tamil, Bengali, Telugu, and Malayalam locally | ✅ Working |
| **Tribal Dictionaries** | Access 2,400+ words in Nicobarese and Great Andamanese | ✅ Working |
| **On-device Voice STT** | Speak directly into the app for hands-free translation (Whisper) | ✅ Working |
| **Camera Translator** | Scan local restaurant menus, signs, or documents | ✅ Working |
| **Common Phrases** | Quick-access to survival phrases (greetings, directions, food) | ✅ Working |
| **Cultural Hub** | Learn about the heritage, traditions, and history of the tribes | 🧪 *Coming Soon* |
| **Community Board** | Connect with other travelers and local guides | 🧪 *Coming Soon* |
| **AR Translator** | Live object detection with translated overlays | ⚠️ *Experimental* |

> **Note:** This version skips role-selection and dives straight into the unified Dashboard.

---

## ⚡ Why SpeechMate?

| Feature | Google Translate | Traditional Phrasebooks | SpeechMate (General Edition) |
| :--- | :--- | :--- | :--- |
| **Tribal Languages** | No Nicobarese/Aka-Jeru | Extremely rare/outdated | ✅ Full Support |
| **Connectivity Required** | Yes (for lesser known langs) | None | ✅ Works fully offline* |
| **Voice Translation** | Yes | No | ✅ Built-in offline STT |
| **Camera Translation** | Yes | No | ✅ Supported |
| **Cultural Context** | None | Limited | ✅ Built-in Culture Hub |

> *\*Core vocabulary, Whisper STT, and translation algorithms run 100% on-device.*

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

> No generative AI or cloud LLMs. All translation is deterministic dictionary + algorithmic NLP, ensuring zero data privacy leaks.

### Technical Specs

| Metric | Value | Notes |
| :--- | :--- | :--- |
| App size | ~250 MB | Includes 141 MB Whisper model |
| STT latency | ~600ms | Tested on a mid-range Android (Snapdragon 6xx). |
| Translation speed | <100ms | SQLite indexed lookup |
| Min Android | API 24 | Android 7.0+ |

---

## 🚀 Installation

```bash
# 1. Clone the General branch
git clone -b speechmate_general https://github.com/sathiyatskrj/Speechmate.git
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

## 📜 Licensing

SpeechMate uses a **split-licensing model** to keep the source code open while strictly protecting indigenous data sovereignty.

### 1. Software Code: Apache 2.0
All source code in this repository is licensed under the [Apache License 2.0](LICENSE). You are free to use, modify, and distribute the software for commercial and non-commercial purposes.

### 2. Linguistic Data: CC BY-NC 4.0
All dictionary entries, audio recordings, and cultural content (located in `assets/data/` and `assets/audio/`) are licensed under **Creative Commons Attribution-NonCommercial 4.0 (CC BY-NC 4.0)**, combined with Traditional Knowledge (TK) protocols. See [DATA_TERMS.txt](DATA_TERMS.txt) for details.

**Key rules for the data:**
- 🚫 **No Commercial Use:** You may not sell, monetize, or use the data in commercial products without written consent from the relevant tribal council.
- 🚫 **No AI Training:** You may not use this data to train commercial AI or LLMs.
- ✅ **Educational/Tourism Use:** You may use the data freely for non-commercial research, personal learning, and respectful tourism tools with proper attribution.

---

<p align="center">
  Bridging the gap between travelers and the rich heritage of the Andaman &amp; Nicobar Islands.
</p>
