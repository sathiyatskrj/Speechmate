# Privacy Policy — SpeechMate

**Last updated:** 28 May 2026  
**Effective date:** 28 May 2026  
**App name:** SpeechMate  
**Developer:** Sathiyat S.K.R.J  
**Contact:** [sathiyatskrj@github.com](mailto:sathiyatskrj@github.com)  
**Repository:** [github.com/sathiyatskrj/Speechmate](https://github.com/sathiyatskrj/Speechmate)

---

## Overview

SpeechMate is a **100% offline-first** language translation and cultural immersion app for the Andaman & Nicobar Islands. This privacy policy explains what data the app collects, stores, and shares.

**The short version:** We collect **nothing**. All data stays on your device.

---

## Data Collection

### Data We Do NOT Collect

SpeechMate does **not** collect, transmit, or share any of the following:

- ❌ Personal information (name, email, phone number)
- ❌ Location data (GPS coordinates are processed on-device only and never transmitted)
- ❌ Voice recordings (all speech-to-text processing happens entirely on-device via Whisper)
- ❌ Camera images (all OCR and object detection processing happens on-device via ML Kit)
- ❌ Usage analytics or telemetry
- ❌ Crash reports
- ❌ Advertising identifiers
- ❌ Device identifiers
- ❌ Cookies or tracking pixels

### Data Stored Locally on Your Device

The following data is stored **locally on your device only** and is never transmitted to any server:

| Data | Purpose | Storage |
| :--- | :--- | :--- |
| Learning progress (XP, streak, level) | Track your vocabulary learning journey | Android SharedPreferences |
| Dictionary entries | Offline translation lookups | SQLite database (on-device) |
| User-added vocabulary | Custom words you add to your personal dictionary | SQLite database (on-device) |
| App settings and preferences | Theme, language selection, keyboard settings | Android SharedPreferences |

This data is stored using standard Android local storage mechanisms and is automatically deleted when you uninstall the app.

---

## Permissions

SpeechMate requests the following Android permissions. All processing associated with these permissions happens **entirely on-device**:

| Permission | Purpose | Data Leaves Device? |
| :--- | :--- | :---: |
| **Microphone** | On-device speech-to-text via Whisper (offline) | ❌ No |
| **Camera** | On-device OCR text scanning and AR object detection via ML Kit (offline) | ❌ No |
| **Storage** | Save Whisper STT model file for offline use | ❌ No |
| **Internet** | One-time download of Whisper model (~141 MB) and ML Kit language packs on first use | Only model download |

> **Note:** After the initial model downloads, the app functions **100% offline** with zero network activity.

---

## Third-Party Services

SpeechMate uses the following third-party libraries. None of them transmit user data:

| Library | Purpose | Data Transmitted? |
| :--- | :--- | :---: |
| **Google ML Kit** (on-device) | Text recognition, object detection, offline translation | ❌ No (on-device models) |
| **Whisper (OpenAI, via whisper.cpp)** | On-device speech-to-text | ❌ No (local C++ inference) |
| **Flutter** | Cross-platform UI framework | ❌ No |
| **SQLite** | Local database for dictionaries | ❌ No |

---

## Children's Privacy

SpeechMate does not knowingly collect any personal information from children under 13. The app does not require account creation, login, or any personal data input.

---

## Data Sharing

We do **not** share any data with third parties. There is no data to share — the app operates entirely offline after initial setup.

---

## Data Retention and Deletion

- All data is stored locally on your device.
- Uninstalling the app permanently deletes all locally stored data.
- There is no cloud backup or remote storage of any user data.

---

## Indigenous Data Sovereignty

SpeechMate contains linguistic data (dictionary entries, audio recordings) from endangered Nicobarese and Great Andamanese languages. This data is licensed under **Creative Commons Attribution-NonCommercial 4.0 (CC BY-NC 4.0)** with Traditional Knowledge (TK) protocols to protect indigenous data sovereignty. See [DATA_TERMS.txt](DATA_TERMS.txt) for details.

---

## Changes to This Policy

We may update this privacy policy from time to time. Any changes will be posted in this file and reflected in the "Last updated" date above. Continued use of the app after changes constitutes acceptance of the updated policy.

---

## Contact

If you have questions about this privacy policy, please contact:

- **GitHub Issues:** [github.com/sathiyatskrj/Speechmate/issues](https://github.com/sathiyatskrj/Speechmate/issues)
- **Repository:** [github.com/sathiyatskrj/Speechmate](https://github.com/sathiyatskrj/Speechmate)

---

<p align="center">
  <em>SpeechMate: 100% offline · 100% on-device · zero data collection</em>
</p>
