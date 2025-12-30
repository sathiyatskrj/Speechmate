🎬 Speechmate: The 2-Minute Technical Sprint (Code-Focused)
Target: Judges & Devs who want to see the CODE.
Duration: 2 Minutes EXACTLY.

---

### 0:00 - 0:20 | The Hook
*(Visual: Fast cuts: 'SpeechMate' Logo -> Tribal Classroom -> App translating voice)*

**Developer:**
"This is Speechmate. It’s not just a dictionary; it’s an **Offline AI Platform** designed to preserve **ANY** indigenous language, starting with Nicobarese. We built it with **Flutter** for a stunning 60fps UI that runs anywhere. But the real innovation? It's what's under the hood."

### 0:20 - 0:50 | The Hybrid Engine (Flutter + C++)
*(Visual: Open `lib/services/whisper_service.dart` at line 170. Highlight `MethodChannel('speechmate/whisper')`. Then cut to `android/app/src/main/kotlin/MainActivity.kt` showing the JNI bridge.)*

"Speechmate is a **Hybrid Beast**. We needed offline Speech-to-Text, so we integrated **OpenAI’s Whisper**, but not via Python. We run the high-performance **C++ port** directly on the device using **JNI** and MethodChannels."

*(Visual: Open `lib/services/whisper_service.dart` line 180. Zoom in on `compute(_transcribeInBackground, ...)`)*

"The challenge? Main-thread AI freezes the UI. **The Fix:** We use **Flutter Isolates** via the `compute` function to spawn a dedicated background thread. This keeps animations buttery smooth while the AI crunches numbers."

### 0:50 - 1:20 | The Technical Fixes
*(Visual: Split Screen Code Showcase)*

"We didn't stop there. 
1. **Audio**: Whisper demands **16kHz 16-bit PCM**.
   *(Visual: Show `lib/screens/student_dash.dart` line 143: `RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000)`)*

2. **Silence Detection**: We added a native C++ energy check.
   *(Visual: Show `android/app/src/main/cpp/native-lib.cpp`. Highlight `float energy = ...` and `if (energy < 0.002f)`)*
   "If you say nothing, the native layer kills the process instantly—saving battery."

3. **App Size**: We slashed the APK from 150MB to **35MB**.
   *(Visual: Open `android/app/build.gradle` line 29. Highlight `splits { abi { enable true ... } }`)*
   "We use Gradle ABI splits to bundle only the binaries the user's phone actually needs."

### 1:20 - 1:45 | Roles & Data
*(Visual: Open `assets/data/dictionary.json`. Scroll rapidly to show thousands of lines.)*

"Data is local. We use optimized JSON assets for **O(1) lookup speeds**. Zero latency."
"The UX is role-based. Students get a 'Fairyland' with **Rive animations**. Teachers get an Admin Dashboard with a **Voice Vault** and **Simulation Mode**."

### 1:45 - 2:00 | The Close
*(Visual: Developer Camera -> GitHub Repo QR Code)*

"Speechmate is scalable, offline-first, and open-source. We’re already ready for the next language. Check out the code, and let’s save history—one word at a time."

*(Fade to Black)*
