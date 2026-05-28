# SpeechMate — Architecture Deep Dive (Explorer Edition v1.5.0)

## System Overview

```mermaid
graph TD
    User([User: Voice / Text / Camera]) --> UI[Flutter UI · Riverpod State]
    UI --> Service[Service Layer]

    subgraph "On-Device Intelligence"
        Service --> |WhisperService| Whisper[Whisper Base · Native C++ via NDK 27]
        Service --> |NeuralEngine| NLP[Offline Translation Pipeline]
        Service --> |ML Kit| AR[Object Detection + Image Labeling]
        Service --> |ML Kit| Regional[Regional Language Translation]
        Service --> |NativeEdgeService| Native[C++ NDK 27 · 100 Native Integrations]
    end

    subgraph "Local Data (SQLite)"
        Service --> DB[DatabaseManager]
        DB --> Words[2,400+ Nicobarese Words]
        DB --> Phrases[Classroom Phrases]
        DB --> Dialects[5 Dialect Variants]
        DB --> GA[Great Andamanese Lexicon]
        DB --> FC[SRS Flashcards]
    end

    Whisper --> |Transcript| NLP
    Regional --> |English pivot| NLP
    NLP --> |Translation| UI
    AR --> |Object Labels| NLP
```

---

## Service Layer

| Service | Responsibility |
| :--- | :--- |
| `WhisperService` | Native C++ Whisper Base inference via NDK 27. Handles audio chunking, VAD, and transcript output. |
| `NeuralEngine` / `TranslationService` | 10-stage offline translation pipeline (see below). |
| `NativeEdgeService` | Unified Dart FFI gateway to all C++ native integrations with graceful PC mock fallback. |
| `DatabaseManager` | SQLite wrapper. Seeds all JSON lexicons on first launch. Indexed for O(1) dictionary lookup. |
| `ProgressService` | SharedPreferences-backed XP, streak, and level state. |
| `GamificationService` | Mission generation, XP award logic, level-up thresholds. |
| `FeedbackService` | Stores user-submitted word corrections locally for elder/teacher review. |

---

## Offline Translation Pipeline (10 Stages)

All translation is **deterministic** — no neural networks, no generative AI.

| Stage | Method | Purpose |
|:---|:---|:---|
| 1 | **Full Phrase Match** | Exact sentence lookup in phrase table |
| 2 | **Bigram Match** | 2-word compound lookup |
| 3 | **Trigram Match** | 3-word compound lookup |
| 4 | **Exact Dictionary Lookup** | O(1) indexed SQLite match |
| 5 | **Context Disambiguation** | Resolves polysemous words via surrounding tokens |
| 6 | **Stemming** | 15+ English suffix rules (e.g., -ing, -ed, -s) |
| 7 | **Synonym Expansion** | 200+ curated synonym mappings |
| 8 | **Soundex Phonetic Match** | Catches misspellings by phonetic similarity |
| 9 | **Compound Word Decomposition** | Splits compounds (e.g., "rainforest" → "rain" + "forest") |
| 10 | **Fuzzy Search** | Levenshtein edit-distance matching (max distance: 2) |

> **Note:** Stages 5–10 are implemented but have not been benchmarked for accuracy against a held-out test set. Accuracy metrics are a roadmap item.

---

## Regional Translation Flow

```
User input (Hindi / Tamil / Bengali / Telugu / Kannada)
    │
    ▼
Google ML Kit / offline model
    │
    ▼ (English pivot text)
NeuralEngine (10-stage pipeline)
    │
    ▼
Nicobarese output
```

| Language | Engine | Connectivity |
| :--- | :--- | :--- |
| Hindi | Google ML Kit | ✅ Offline |
| Tamil | Google ML Kit | ✅ Offline |
| Bengali | Google ML Kit | ✅ Offline |
| Telugu | Google ML Kit | ✅ Offline |
| Kannada | Google ML Kit | ✅ Offline |

> ML Kit models must be downloaded on first use. After download, they operate fully offline.

---

## Native Integration Stack (v1.5.0)

NativeEdgeService is the unified Dart FFI gateway to all C++ subsystems:

| Subsystem | Integrations | Key APIs |
| :--- | :---: | :--- |
| **Audio DSP** | 10 | VAD, Noise Gate, PCM Downmix, Mel Spectrograms, TD-PSOLA |
| **AI/Speech** | 10 | Whisper GGUF, Cosine similarity, SM-2 SRS, TTS phonetics |
| **Vision/OCR** | 10 | Binarization, Camera2 streaming, ML Kit OCR, AR canvas overlays |
| **Mesh Sync** | 10 | Bonjour NSD, XOR encryption, CRDT merge, TEE Keystore |
| **Bat-Sync** | 10 | Manchester bitstream, Goertzel DFT, raw PCM loopback, CRC-16 verify |
| **GIS/Eco** | 10 | GNSS GPS, OSM tile render, WGS-84 converter, R-Tree index, Lux governor |
| **Security** | 10 | AES-GCM, ChaCha20, Ed25519 signing, Keystore TEE binding |
| **SIMD/Perf** | 10 | ARM NEON math acceleration, buffer vectorization, FFT |
| **Utilities** | 10 | SQLite telemetry, crash reporter, TD-PSOLA, collab whiteboard, media hub |
| **Environment** | 10 | Wind DSP compensation, SOS beacon, lunar calendar, dialect heatmap |

---

## Data Layer

All linguistic data lives in `assets/data/` and is seeded to SQLite on first app launch.

| File | Category | Approx. Entries |
| :--- | :--- | :--- |
| `dictionary.json` | Core Nicobarese | 2,400+ |
| `dictionary_numbers.json` | Numbers | ~20 |
| `dictionary_nature.json` | Nature | ~30 |
| `dictionary_colors.json` | Colors | ~15 |
| `dictionary_feelings.json` | Emotions | ~20 |
| `dictionary_things.json` | Everyday objects | ~40 |
| `dictionary_body_parts.json` | Body parts | ~30 |
| `dictionary_animals.json` | Animals | ~20 |
| `dictionary_magic.json` | Greetings / Magic words | ~25 |
| `dictionary_family.json` | Family | ~20 |
| `dictionary_phrases.json` | Classroom phrases | ~30 |
| `dictionary_dialects.json` | 5-dialect comparison | large |
| `dictionary_great_andamanese.json` | Great Andamanese | 1,000+ |

### Entry Format

```json
{
  "english": "Water",
  "nicobarese": "Mak",
  "emoji": "💧",
  "audio": "water.mp3"
}
```

---

## Why Offline-First?

- **Accessibility** — Andaman & Nicobar islands have frequent signal dead zones.
- **Privacy** — Voice recordings never leave the device.
- **Data sovereignty** — Indigenous linguistic data is stored locally, not by a cloud provider.
- **Speed** — No server round-trips; dictionary responses are <100ms.

---

## Technical Specs (v1.5.0)

| Metric | Value | Notes |
| :--- | :--- | :--- |
| Build version | `1.5.0+10` | pubspec.yaml + build.gradle + dart.yml |
| APK size | ~80 MB | Whisper model downloaded post-install (~141 MB) |
| Total on-device | ~220 MB | After Whisper download |
| STT latency | ~600ms | Tested on mid-range Android (Snapdragon 6xx) |
| Translation speed | <100ms | SQLite indexed lookup |
| Min Android | API 24 | Android 7.0+ |
| NDK | 27 | Required for Whisper C++ bridge |
| Native integrations | 100+ | C/C++/Java/Kotlin across 10 subsystems |

---

## Adding a New Language

SpeechMate is language-agnostic by design:

1. Create `assets/data/dictionary_<lang>.json`
2. Add audio to `assets/audio/<lang>/`
3. Register in `main.dart` → `seedCategoryFromJson()`
4. Add a language tile in `app_language_select.dart`
