# SpeechMate — Prior Art Evidence Record

**Last updated:** June 2026  
**Purpose:** Structured record of prior art establishing creation priority for SpeechMate's code and linguistic data.

> This document is part of the IP protection record for the SpeechMate project. It should be maintained and updated whenever new significant milestones are achieved.

---

## 1. Software Prior Art

### First Public Commit
- **Date:** December 9, 2025
- **Commit hash:** `88169e9043ffc8bd2ea9a2d5d831fcc3ea5f48ff`
- **Message:** "Initial commit"
- **Verification:** GitHub cryptographic commit history (non-repudiable)

### Repository
- **URL:** https://github.com/sathiyatskrj/Speechmate
- **Corpus name:** sathiyatskrj/Speechmate
- **Primary license:** Apache 2.0
- **Data license:** CC BY-NC 4.0 (see `DATA_TERMS.txt`)

### Novel Technical Elements (Prior Art Claims)
These features are documented in the codebase and constitute prior art preventing third-party patents:

| Feature | Files | First Commit |
|---|---|---|
| 10-stage offline NLP pipeline for tribal languages | `lib/services/local_llm_service.dart` | Dec 2025 |
| SM-2 SRS for indigenous vocabulary | `lib/services/database_manager.dart` | Dec 2025 |
| CRDT mesh sync for offline classrooms | `lib/services/` | Dec 2025 |
| On-device Whisper ASR integration | `android/app/src/main/cpp/` | Dec 2025 |
| First Nicobarese Android IME keyboard | `lib/services/native_edge_service.dart` | Dec 2025 |
| Offline Flutter app for endangered tribal language | `lib/main.dart` | Dec 2025 |

---

## 2. Linguistic Data Prior Art

### Dataset Description
- **Languages:** Car Nicobarese, Great Andamanese
- **Content:** 3,400+ vocabulary entries, dialectal variants, phrases, audio recordings
- **Format:** JSON dictionaries with structured metadata
- **Watermark ID:** `SM-NIC-LANG-2025-v1`

### Data Files and Fingerprints
Run `python scripts/verify_watermarks.py` to generate current fingerprints.

Reference fingerprints as of June 2026 commit:

| File | Entries | SHA-256 (first 32 chars) |
|---|---|---|
| dictionary.json | 623 | `87f100ec22bd0ca6d102f782fc41df71` |
| dictionary_animals.json | 8 | `d37966c3687332d4ea7e2ecbf85117ee` |
| dictionary_body_parts.json | 12 | `d2301ad413ec0d53d4adc6b1bc324eda` |
| dictionary_colors.json | 10 | `d185d1a48afd306ab76ca7a6621cadc6` |
| dictionary_dialects.json | 346 | `1d31def6032386feaac21da8d21fe23c` |
| dictionary_family.json | 7 | `dc689803dd573c5d42f9b95b897c8539` |
| dictionary_feelings.json | 10 | `c43b17679539282c962dfd4e44d6af98` |
| dictionary_great_andamanese.json | 2251 | `e074c1648d02a491fc555a649901084658` |
| dictionary_magic.json | 9 | `f47d2d7006c04ca5abc5acb7ef680c25` |
| dictionary_nature.json | 13 | `24eaff596da7959fa5cf14a78f8a3702` |
| dictionary_numbers.json | 10 | `96114ce72c632d2e0151bd0f35b382b5` |
| dictionary_phrases.json | 9 | `c1e6f33d94d29941db9b72fa620d21cf` |
| dictionary_things.json | 22 | `98f69aad675895444afc21ba796435ef` |
| phrases_great_andamanese.json | 10 | `e0d36c5164e4232508944d8cc15ad575` |

### Data Provenance
The linguistic data was compiled through original fieldwork documentation of Nicobarese and Great Andamanese, with community participation from speakers of these languages in the Andaman and Nicobar Islands. The compilation work represents original authorship under the Indian Copyright Act 1957.

---

## 3. Competition & Public Disclosure Record

### VBYLD 2026 (Vision Beyond Youth Leadership Development)
- **Event:** National Level Competition
- **Date:** January 9, 2026
- **Knowledge Partner:** IIT Bombay
- **Significance:** Independently verified public disclosure with timestamp, establishing prior art date for all features present in the submitted version.
- **Status:** National-level finisher

> This constitutes a **public disclosure event** — all technical methods disclosed in the submission are now prior art and cannot be patented by third parties.

---

## 4. Canary (Honeypot) Record

A set of synthetic canary entries are embedded in `assets/data/canary_words.json`. These are invented but linguistically plausible Nicobarese compound expressions that do not exist in any other published source.

**Purpose:** If any of the five canary entries (marked `SM-C-001` through `SM-C-005`) appear in a third-party dataset, AI model output, or app, this definitively identifies SpeechMate as the source of the data breach.

The canary entries are not public knowledge — this document should be kept **in the repository** but the specific canary words should be separately documented offline for enforcement purposes.

---

## 5. Enforcement Actions Record

| Date | Incident | Status | Notes |
|---|---|---|---|
| — | — | — | No incidents recorded yet |

---

## 6. Recommended Ongoing Actions

- [ ] Run `python scripts/generate_prior_art_snapshot.py` monthly and email output to yourself
- [ ] Upload a snapshot to [web.archive.org](https://web.archive.org) every quarter  
- [ ] Set Google Alerts for: "SpeechMate", "Nicobarese app", "tribal language flutter"
- [ ] Search Play Store for "Nicobarese" and "tribal language" monthly
- [ ] Apply for trademark "SpeechMate" at [ipindia.gov.in](https://ipindia.gov.in) — Class 9 + 41
- [ ] Register copyright at [copyright.gov.in](https://copyright.gov.in) — ₹500/work
- [ ] Publish arXiv pre-print describing NLP pipeline + CRDT mesh architecture
