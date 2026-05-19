# SpeechMate — Internal Development Status (NOT PUBLIC)

> ⚠️ This file is .gitignored. It is for internal team reference only.
> The public-facing status is in README.md and docs/features.md.

## Honest Feature Status

### Needs Work Before Pilot
- AR Translator: Works on static images only. Live video overlay is unstable on some devices.
- Omni-Broadcast: Architecture built but latency on low-end devices not validated.
- Memory Palace: UI complete, needs content population.
- Structured Lessons: UI shell only — no curriculum content yet.
- Dialect Heatmap: UI complete, data is placeholder only.
- Culture Hub: UI complete, content is placeholder.
- Community Hub: UI only — no backend.
- 8-Language UI: Strings partially translated.
- Virtual Pet: Functional but pedagogical value untested.
- Certification Levels: UI complete, not linked to real assessment.
- Nature Hub: Data is placeholder.
- Oral History Radio: UI shell, no real recordings.
- Tuhet Mapper: Concept UI only.

### Known Issues
- APK is ~250 MB (141 MB Whisper model). Need lean build.
- Malayalam requires one-time download (local ML Kit model).
- No user testing conducted.
- No accuracy benchmarks for translation pipeline stages 5-10.
- No school deployment yet.
- No community audio recordings from native speakers.
- Linguistic data not validated by native speakers or tribal council.

### Pre-Pilot Gaps
- No pilot users
- No measurable educational outcomes
- No institutional support letters
- No evidence of adoption
- No teacher testimonials

## APK Size Breakdown
- Whisper model (ggml-base.bin): 141 MB
- ML Kit models: ~40 MB
- Audio files: ~30 MB
- Flutter + dependencies: ~30 MB
- JSON dictionaries: ~5 MB
- Total: ~250 MB
