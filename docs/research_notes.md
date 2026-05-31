# SpeechMate Dashboard Inventory — Student & General Public Feature Sets
### Version 1.5.0 — speechmate_general branch

A complete, granular mapping of all categories, interactive platforms, translation tools, and diagnostic modules embedded in the Student Dashboard Bento Grid and the Teacher Dashboard Bento Grid.

---

## 🚀 1. Student Dashboard Bento Grid Inventory

The Student Dashboard is partitionable into five specialized functional categories, comprising **39 distinct modules/options**:

### A. Premium Interactive Features (13 items)
1. **AR Object Translator (`ARTranslatorScreen`):** Live augmented reality camera identifying objects and labelling them in native Nicobarese in real-time.
2. **Voice Vault (`VoiceVaultScreen`):** Interactive microphone booth where students record native audio, building an organic local speech corpus.
3. **Book Scanner (`CameraTranslationScreen`):** Advanced on-device OCR camera translating printed text documents instantly.
4. **Interactive Games Hub (`GamesHubScreen`):** Gamification center hosting Word Match, Word Scramble, Word Runner, and Flash Cards.
5. **Classroom Leaderboard (`LeagueScreen`):** Tactical competitive league podium showing weekly student rankings and XP stats.
6. **Achievement Showcase (`AchievementBadgesScreen`):** Dynamic display cabinet rendering 20+ unlockable medals and credentials.
7. **Cultural Calendar (`CulturalCalendarScreen`):** Lunar-aware tribal planner indicating seasonal celebrations (ap pig feasts, outrigger races) and custom events added by the teacher.
8. **Chat Translate (`BetaChatScreen`):** Interactive AI messaging console running local dictionaries for vocabulary translation dialogues.
9. **Voice Translate (`VoiceTranslatorScreen`):** Bidirectional on-device speech-to-speech translator with native voice playback.
10. **Pronunciation Practice (`PronunciationChallengeScreen`):** Micro-learning microphone dashboard evaluating student speech accent accuracy.
11. **Conversation Mode (`ConversationModeScreen`):** Split-screen dialog helper for side-by-side conversational practices.
12. **Situational Phrasebook (`PhrasebookScreen`):** Organized reference tables covering travel, shopping, and everyday phrases.
13. **Emergency SOS Phrases (`SOSPhrasesScreen`):** Instant glottal-sound and phonetic guides for extreme weather, medical, and emergency scenarios.

### B. Core Learning Categories (9 items)
14. **Numbers (`DynamicCategoryScreen`):** Integers, counting terms, and monetary expressions.
15. **Nature (`DynamicCategoryScreen`):** Forestry, plants, beaches, weather, and ocean conditions.
16. **Feelings (`DynamicCategoryScreen`):** Emotions, status indicators, and health expressions.
17. **Colors (`DynamicCategoryScreen`):** Color terms and shading vocabulary.
18. **Things (`DynamicCategoryScreen`):** Household items, tools, and structures.
19. **Body Parts (`BodyPartsScreen`):** Fully illustrated anatomical guide mapping names of bones, muscles, and organs.
20. **Animals (`DynamicCategoryScreen`):** Traditional names for jungle fauna, insects, and fish.
21. **Magic Words (`DynamicCategoryScreen`):** Greetings, expressions of gratitude, and polite phrases.
22. **Family (`DynamicCategoryScreen`):** Comprehensive terms for maternal/paternal lineage and family tree labels.

### C. Offline Regional Translators (6 items)
23. **Omni-Broadcast (`OmniTranslatorScreen`):** Splits spoken phrases and broadcasts translations into 5 regional scripts simultaneously.
24. **Hindi Translator (`RegionalTranslatorScreen`):** English/Nicobarese ↔ Hindi translator.
25. **Tamil Translator (`RegionalTranslatorScreen`):** English/Nicobarese ↔ Tamil translator.
26. **Bengali Translator (`RegionalTranslatorScreen`):** English/Nicobarese ↔ Bengali translator.
27. **Telugu Translator (`RegionalTranslatorScreen`):** English/Nicobarese ↔ Telugu translator.
28. **Malayalam Translator (`RegionalTranslatorScreen`):** English/Nicobarese ↔ Malayalam translator.

### D. Advanced / Discovery (8 items)
29. **Great Andamanese Hub (`GAHubScreen`):** Standalone module supporting the endangered Aka-Jeru language.
30. **Nature Hub (`FloraFaunaScreen`):** Dynamic offline identifier for local plants and birds, highlighting ecological and traditional medical uses.
31. **Oral History (`StoryRadioScreen`):** Digital audio radio playing archived narratives, songs, and historical accounts from island elders.
32. **Tuhet Kinship (`KinshipMapperScreen`):** Interactive family tree mapping traditional landholdings and relational networks.
33. **Island Explorer (`DialectHeatmapScreen`):** Stylized custom map marking villages and geographic dialect patterns.
34. **Memory Palace (`MemoryPalaceScreen`):** Virtual spatial village linking terms to virtual objects.
35. **Community (`CommunityScreen`):** Local off-grid collaborative messaging zone.
36. **AI Setup (`AISetupScreen`):** Neural configuration dashboard controlling Whisper model parameters.

### E. Utilities & Dialogs (3 items)
37. **System Keyboard Settings Launcher:** Interactive tile triggering Android IME system configuration menus.
38. **In-App Sandbox Keyboard:** Bottom-sheet drawer containing the specialized keyboard for typing practice.
39. **Feedback & Corrections (`FeedbackScreen`):** Direct communication pipeline for vocabulary correction submissions.

---

## 📋 2.  Linguistic & Dictionary Analysis Audit (v1.5.0)

A quantitative and qualitative analysis of SpeechMate's local dictionary payloads shows robust coverage with structural gaps that must be closed for NLP and high-stress safety scenarios.

### 📊 A. Vocabulary Statistics Summary
*   **Total Dictionary Entries:** `3,340` (seeded across Car Nicobarese, Great Andamanese Aka-Jeru, dialects, body parts, animals, feelings, and kinship files).
*   **Unique English Keywords:** `2,663`
*   **Pre-recorded Audio Coverage:** `90` high-fidelity MP3s available in assets (primarily covering nature, animals, numbers, feelings, and basic phrases).

### 🔍 B. Essential NLP & RAG Gaps
To build an offline semantic search (RAG) and conversational AI translator, the localized corpus must support grammatical connectives, question tags, and core action verbs. The audit isolated **164 missing essential terms**:
*   *Pronouns & Questions (17 items):* `she`, `it`, `who`, `what`, `when`, `why`, `how`, `which`, `whose`, `how many`, `how much`.
*   *Grammar Connectives (25 items):* `or`, `but`, `because`, `if`, `so`, `very`, `every`, `each`, `only`, `again`, `still`, `already`, `just`, `here`, `there`, `out`, `off`, `with`, `without`, `about`, `from`, `at`, `by`, `for`, `of`.
*   *Essential Verbs & Time (37 items):* `be`, `have`, `want`, `need`, `like`, `put`, `find`, `feel`, `fly`, `carry`, `throw`, `push`, `fight`, `die`, `born`, `grow`, `work`, `build`, `break`, `fix`, `harvest`, `before`, `after`, `always`, `never`, `sometimes`, `week`, `hour`, `minute`, `second` + days of the week.
*   *Indigenous & Island Thematic Gaps (85 items):* Includes navigation directions, health/medical terminology, maritime/outrigger operations, government services, climate hazards, and cultural/spiritual vocabulary.

### 🎙️ C. Safety-Critical TTS Audio Recordings Checklist
The 23 safety phrases hardcoded in `SOSPhrasesScreen` currently bypass recorded playback and rely on standard device TTS (`en-IN`), yielding unintelligible accents. Native speaker audio recordings must be added directly into `assets/audio/phrases/` using the following exact mapped filenames to satisfy `TtsService` auto-lookups:
1.  **I need a doctor:** `i_need_a_doctor.mp3`
2.  **It hurts here:** `it_hurts_here.mp3`
3.  **I am allergic:** `i_am_allergic.mp3`
4.  **I need medicine:** `i_need_medicine.mp3`
5.  **Call an ambulance:** `call_an_ambulance.mp3`
6.  **I cannot breathe:** `i_cannot_breathe.mp3`
7.  **I am lost:** `i_am_lost.mp3`
8.  **Where am I?:** `where_am_i.mp3`
9.  **Help me please:** `help_me_please.mp3`
10. **Where is the police station?:** `where_is_the_police_station.mp3`
11. **Where is the hospital?:** `where_is_the_hospital.mp3`
12. **I need to go to the jetty:** `i_need_to_go_to_the_jetty.mp3`
13. **Call the police:** `call_the_police.mp3`
14. **I need help from authority:** `i_need_help_from_authority.mp3`
15. **Someone stole my belongings:** `someone_stole_my_belongings.mp3`
16. **I am a tourist / visitor:** `i_am_a_tourist_visitor.mp3`
17. **This is an emergency:** `this_is_an_emergency.mp3`
18. **I do not understand:** `i_do_not_understand.mp3`
19. **Please speak slowly:** `please_speak_slowly.mp3`
20. **I need water:** `i_need_water.mp3`
21. **I need food:** `i_need_food.mp3`
22. **Thank you for helping:** `thank_you_for_helping.mp3`
23. **My name is...:** `my_name_is.mp3`
