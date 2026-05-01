# SpeechMate — Linguistic Data Guide

## Overview

All linguistic data is stored in `assets/data/` as JSON files and seeded into a local SQLite database on first app launch. No data is sent to a cloud server.

---

## Lexicon Structure

### Core Word Entry

```json
{
  "english": "Water",
  "nicobarese": "Mak",
  "emoji": "💧",
  "audio": "water.mp3",
  "category": "nature",
  "dialect": "car"
}
```

| Field | Required | Description |
| :--- | :---: | :--- |
| `english` | ✅ | English gloss |
| `nicobarese` | ✅ | Target language word |
| `emoji` | ✅ | Visual cue for young learners |
| `audio` | ✅ | Filename in `assets/audio/` |
| `category` | ⚠️ | Used for category filtering |
| `dialect` | ⚠️ | `car`, `central`, `coast`, `teressa`, `chowra` |

### Dialect Entry (dictionary_dialects.json)

```json
{
  "english": "Water",
  "car": "Mak",
  "central": "Mak",
  "coast": "Mik",
  "teressa": "Ma",
  "chowra": "Mah"
}
```

---

## Data Files

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

---

## Adding a New Language Module

SpeechMate is language-agnostic by design. To add a new language:

1. **Create the lexicon:**
   ```
   assets/data/dictionary_<language_code>.json
   ```

2. **Add audio files:**
   ```
   assets/audio/<language_code>/word.mp3
   ```

3. **Register in main.dart:**
   ```dart
   await seedCategoryFromJson('dictionary_<language_code>.json', '<Category Name>');
   ```

4. **Add a UI tile in `app_language_select.dart`**

---

## Data Sovereignty & Usage Terms

The linguistic data in this repository represents the cultural heritage of the **Nicobarese** and **Great Andamanese** peoples.

### Permitted (non-commercial)
- ✅ Research and academic study
- ✅ Non-commercial educational tools
- ✅ Language documentation and preservation
- ✅ Derivative non-commercial apps with attribution

### Not Permitted
- ❌ Commercial use or sale of the data
- ❌ Training commercial AI/ML models on this data
- ❌ Redistribution without attribution
- ❌ Any use without respecting the communities of origin

### For commercial or institutional use
Contact the appropriate tribal councils or the **Andaman & Nicobar Administration / Department of Tribal Welfare** for formal permission.

---

## Contributing Linguistic Corrections

If you are a community member, linguist, or teacher and you find errors:

1. Use the **in-app Feedback System** (Student Dashboard → Feedback button) to flag incorrect words.
2. Or open a GitHub Issue with the tag `[linguistics]` describing the correction and its source.

Community corrections are reviewed before merging. We prioritize corrections from native speakers and certified linguists.

---

## Sources & References

> The current lexicon is a compiled prototype dataset. Formal linguistic validation with community elders has not yet been conducted — this is a priority for the pilot phase.

Potential reference sources for validation:
- CIIL (Central Institute of Indian Languages) published materials
- SIL International's Ethnologue data for Car Nicobarese
- Published academic wordlists (Man, 1889; Whitehead, 1925 — Great Andamanese)
- Direct community elder recording sessions (planned for pilot phase)
