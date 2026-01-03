# Questions for Mentor: Speechmate App Improvement

## 🧠 Technical Architecture & Performance
*   **Speech-to-Text Optimization**: We currently use `whisper.cpp` with a custom C++ integration for offline speech recognition. usage. Are there more efficient ways to handle the model loading/unloading to reduce battery drain on lower-end Android devices without sacrificing too much accuracy?
*   **Asset Management**: As we add more cultural content (images, audio), the app size is growing. What are the best practices for managing large local assets in Flutter for an offline-first app? Should we consider a dynamic download module strategy?
*   **Data Structure**: We are currently using JSON files for our dictionary data. At what scale should we migrate to a local database like SQLite or Drift for better query performance?

## 🎨 User Experience (UX) & Engagement
*   **Dashboard Split**: We recently separated the Student and Teacher dashboards effectively. What are the key metrics we should track to ensure this split is actually serving the distinct needs of both user types effectively?
*   **Gamification Depth**: We've added mini-games and quizzes. In your experience, what are the most high-impact "hooks" for language learning apps to improve daily retention (e.g., streaks, leaderboards, unlockable content)?
*   **Accessibility**: Given our target audience might range in tech-literacy, are there specific accessibility standards or UI patterns we should prioritize to make the app more approachable for elders or non-digital natives?

## 🚀 Product Strategy & Growth
*   **Community Adoption**: adapting to a niche language community (Nicobarese), what are the most effective non-digital strategies to drive adoption? (e.g., school partnerships, community workshops).
*   **Feedback Loop**: What is the most frictionless way to collect user feedback (especially regarding translation accuracy) from users who might be hesitant to type out long bug reports?
*   **Roadmap Prioritization**: We have a lot of features (Printable Planner, Culture Section, Dictionary). How should we balance "fun" features vs. "utility" features to ensure the app is taken seriously as an educational tool?

## 🎓 Cultural & Educational Impact
*   **Content verification**: How can we build a system or feature that allows trusted community elders to "verify" or "approve" new words/translations directly in the app to maintain cultural authority?
*   **Learning pathways**: Currently, the learning is self-directed. Would a structured "Curriculum" feature (Level 1, Level 2) be more effective for this type of language preservation project?
