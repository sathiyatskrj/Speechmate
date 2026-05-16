# SpeechMate — Complete Feature List (v1.6.0 Explorer Edition)

> **Status key:**
> - ✅ Working — built and manually tested
> - ⚠️ Partial — functional but incomplete or dependent on connectivity
> - 🧪 Experimental — built but not validated; may not work on all devices
> - 🆕 New in v1.6.0

---

## Explorer Dashboard (General Public)

| Module | Description | Status |
| :--- | :--- | :--- |
| **Explorer Dashboard** | Bento-grid home screen with quick access to all translation tools | 🆕 ✅ |
| **Word of the Day** | Deterministic daily Nicobarese word with emoji and translation | 🆕 ✅ |
| **Survival Phrase Cards** | Horizontally scrolling cards: Greetings, Food, Directions, Emergency | 🆕 ✅ |
| **Offline Status Chip** | Persistent indicator showing "Fully Offline" connectivity state | 🆕 ✅ |
| **Onboarding Flow** | 3-slide first-launch intro: offline-first, voice translate, heritage mission | 🆕 ✅ |
| **Bidirectional Voice Translate** | Speak in English/Hindi/Tamil/Bengali/Telugu → Nicobarese output with language selector | 🆕 ✅ |
| **Whisper Warm-up** | Pre-initializes Whisper engine during splash for zero cold-start voice lag | 🆕 ✅ |
| **DB Seed Optimization** | Version-hash check skips redundant re-seeding on every cold start | 🆕 ✅ |
| **ML Kit Offline Fallback** | Clear download prompt when regional language models aren't yet available | 🆕 ✅ |
| **Nicobarese → English Reverse Lookup** | Search by Nicobarese word to get English translation | 🆕 ✅ |

---

## Core Translation Features

| Module | Description | Status |
| :--- | :--- | :--- |
| **12 Learning Categories** | Numbers, Nature, Feelings, Colors, Things, Body Parts, Animals, Magic Words, Family, and more — loaded from Nicobarese JSON lexicons | ✅ |
| **Chat Translator** | Conversational translation via offline dictionary + NLP | ✅ |
| **Regional Translators** | Bidirectional: Nicobarese ↔ Hindi, Tamil, Bengali, Telugu (offline); Malayalam (online) | ✅ / ⚠️ |
| **Multilingual Search** | Type in any regional language script — auto-translates to English before Nicobarese lookup | ✅ |
| **Voice Translator** | On-device Whisper Base STT → 10-stage NeuralEngine → Nicobarese output with multi-language input | ✅ |
| **AR Translator** | Camera-based object detection with Nicobarese overlay via ML Kit. 3 lens modes (Auto/Objects/Text). | ⚠️ |
| **Omni-Broadcast** | Speak once → translate to 5 regional languages simultaneously | 🧪 |
| **Document Translation** | Offline PDF/TXT parser → Nicobarese | 🧪 |

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
| **Culture Hub** | Indigenous traditions, festivals, folklore, cultural context | 🧪 |
| **Dialect Comparison** | Side-by-side view across Car, Central, Coast, Teressa & Chowra dialects | ⚠️ |
| **Voice Vault** | Record and preserve oral history or field recordings locally | ✅ |
| **Flora & Fauna Hub** | Endemic species with Nicobarese names and traditional uses | 🧪 |
| **Oral History Radio** | Tribal storytelling archive with playback | 🧪 |
| **Tuhet Mapper** | Kinship structure visualization for indigenous family trees | 🧪 |

---

## Gamification & Engagement

| Engine | Description | Status |
| :--- | :--- | :--- |
| XP & Leveling | 11 named levels with streak multipliers | ✅ |
| Daily Missions | Deterministic daily goal selector | ✅ |
| Confetti | Physics particle effects | ✅ |
| Quick Stats | Live streak, stars, level from SharedPreferences | ✅ |
| Voice Waveform | Animated audio visualizer | ✅ |

---

## System & Performance

| Feature | Description | Status |
| :--- | :--- | :--- |
| **Whisper Base STT** | 141 MB model, native C++ via NDK 27, with VAD + gibberish filtering | ✅ |
| **10-Stage Translation Pipeline** | Deterministic: phrase match → bigram → trigram → dictionary → context → stemming → synonym → soundex → compound → fuzzy | ✅ |
| **SQLite Indexed DB** | O(1) dictionary lookup with version-controlled seeding | ✅ |
| **Offline-First Architecture** | Zero cloud dependency, data sovereignty for indigenous languages | ✅ |
