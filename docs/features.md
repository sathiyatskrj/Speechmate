# SpeechMate — Complete Feature List

> **Status key:**
> - ✅ Working — built and manually tested
> - ⚠️ Partial — functional but incomplete or dependent on connectivity
> - 🧪 Experimental — built but not validated; may not work on all devices

---

## Student Dashboard

| Module | Description | Status |
| :--- | :--- | :--- |
| **12 Learning Categories** | Numbers, Nature, Feelings, Colors, Things, Body Parts, Animals, Magic Words, Family, and more — loaded from Nicobarese JSON lexicons | ✅ |
| **Word Match Game** | Tap the correct Nicobarese word for a shown image | ✅ |
| **Flash Cards** | Audio + image flashcard drill | ✅ |
| **Word Scramble** | Unscramble Nicobarese letters | ✅ |
| **Word Runner** | Timed word identification game | ✅ |
| **SRS Flashcards** | SM-2 spaced repetition for long-term retention | ✅ |
| **Chat Translator** | Conversational translation via offline dictionary + NLP | ✅ |
| **Regional Translators** | Bidirectional: Nicobarese ↔ Hindi, Tamil, Bengali, Telugu (offline); Malayalam (online) | ✅ / ⚠️ |
| **Multilingual Search** | Type in any regional language script — auto-translates to English before Nicobarese lookup | ✅ |
| **XP & Leveling** | 11 named levels (Seedling → Elder) with streak multipliers | ✅ |
| **Daily Missions** | Deterministic daily goal selector — no backend required | ✅ |
| **Confetti System** | Physics-based particle effects on achievements | ✅ |
| **Voice Vault** | Record and preserve oral history or folklore audio locally | ✅ |
| **QR Sync** | Offline peer-to-peer vocabulary and progress sync via QR codes | ✅ |
| **Feedback System** | Users submit linguistic corrections for elder/teacher review | ✅ |
| **AR Translator** | Camera-based object detection with Nicobarese overlay via ML Kit. 3 lens modes (Auto/Objects/Text). | ⚠️ Works on static images; live video overlay experimental |
| **Whisper STT** | On-device speech-to-text (Whisper Base, 141 MB). Fast-path shortcut for common phrases. | ✅ on mid-range Android; low-end not benchmarked |
| **Omni-Broadcast** | Speak once → translate to 5 regional languages simultaneously | 🧪 Architecture built; latency on low-end devices not validated |
| **Memory Palace** | Spatial vocabulary learning linked to a virtual indigenous village map | 🧪 UI complete |
| **Structured Lessons** | Curriculum paths (Level 1–10) | 🧪 UI shell complete |
| **Dialect Heatmap** | Interactive A&N map showing dialect distribution zones | 🧪 UI complete; data is placeholder |
| **Culture Hub** | Indigenous traditions, folklore, cultural context | 🧪 UI complete; content placeholder |
| **Community Hub** | Shared learning feed | 🧪 UI only |
| **8-Language UI** | Interface localized in Nicobarese, Great Andamanese, English, Hindi, Tamil, Malayalam, Telugu, Bengali | 🧪 Strings partially translated |
| **Virtual Pet** | Tamagotchi-style companion with mood states, XP-driven evolution, interactive behaviors | 🧪 Functional; pedagogical value untested |

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
| **Certification Levels** | 10 structured proficiency levels with unlock progression | ⚠️ UI complete; not linked to real assessment |
| **Dialect Comparison** | Side-by-side view across Car, Central, Coast, Teressa & Chowra dialects | ⚠️ |
| **Document Translation** | Offline PDF/TXT parser → Nicobarese | 🧪 Works; no field testing |
| **P2P Sync** | Export/import vocabulary packs via offline ZIP payloads | 🧪 Works; no field testing |
| **Nature Hub** | Flora & fauna database with indigenous names and traditional uses | 🧪 Data placeholder |
| **Oral History Radio** | Tribal storytelling archive with playback | 🧪 UI shell; no real recordings yet |
| **Tuhet Mapper** | Kinship structure visualization for indigenous family trees | 🧪 Concept UI |
| **Voice Translator** | Real-time multilingual voice translation | 🧪 Experimental |

---

## Great Andamanese Hub

A standalone module with 4 tabs:

| Tab | Feature | Status |
| :--- | :--- | :--- |
| **Dictionary** | Searchable GA lexicon (1,000+ entries) with POS filters + TTS | ✅ |
| **Translator** | English → Great Andamanese (exact match + word-by-word fallback) | ✅ |
| **Voice** | Whisper transcription → auto-translation to GA | ✅ |
| **OCR Scanner** | Scan printed English text → translate to GA | ✅ |

---

## Gamification Engines

| Engine | Description | Status |
| :--- | :--- | :--- |
| XP & Leveling | 11 named levels with streak multipliers | ✅ |
| Daily Missions | Deterministic daily goal selector | ✅ |
| Confetti | Physics particle effects | ✅ |
| Quick Stats | Live streak, stars, level from SharedPreferences | ✅ |
| Virtual Pet | Mood states, XP evolution, speech bubbles | 🧪 |
| Voice Waveform | Animated audio visualizer | ✅ |
