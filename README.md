<p align="center">
  <img src="github_readme_ss/banner.png" width="100%">
</p>

<h1 align="center" style="font-family: Arial, sans-serif; color: #FF6F61; text-shadow: 2px 2px 4px rgba(0,0,0,0.5);">
  SPEECHMATE
</h1>

<p align="center">
  <em>"Where Language Barrier Ends."</em>
</p>

<p align="center">
  <a>
    <img src="https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white" alt="DART" />
  </a>
  <a>
    <img src="https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white" alt="Flutter" />
  </a>
  <a>
    <img src="https://img.shields.io/badge/Offline--First-4285F4?style=flat&logo=google&logoColor=white" alt="Offline First" />
  </a>
  <a>
    <img src="https://img.shields.io/badge/License-MIT-green?style=flat" alt="License" />
  </a>
</p>

---

## 🌏 The Mission: More Than Just Code

**Every 14 days, a language dies.** When a language disappears, we don't just lose words; we lose centuries of wisdom, culture, and identity.

## 🏗️ Architecture

<p align="center">
  <img src="https://mermaid.ink/img/pako:eNptkMFuwjAMhl8l8gV64z1w2jFp4jS0N0gIdYmbWBIlKnOaOqR99xUoDA5tciT_-39sxz2JUhIkfF5Pry_GCdu_u-2WbV_fvuw22z0-Nq_vj_eP79vXw9tH_7Z9_Xo97A_73fF4fD4dDx_vH_u_4c_w7_B3-Ef4J_wV/hX--R9JqZRUklKppFSCUolKJSqVqFSiUolKJSpBKUGpBKVSpEqRKkWqFKlSpEqRKkWqFKlSpEqRSiUqlahUolKJSiUqlahUolKJSiUqlahUolKJSiUqlahUolKJSiUqlahUolKJ6l_0C8y5c4E" alt="Clean Architecture Diagram" />
</p>

# Architecture - Clean & Offline First

```mermaid
graph TD
    User([User]) --> UI[Flutter UI Layer]
    UI --> Logic[Business Logic / ViewModels]
    Logic --> Repo[Repository Layer]
    
    subgraph Data Layer
        Repo --> LocalDB[(SQLite / SharedPrefs)]
        Repo --> Assets[JSON Assets]
        Repo --> Whisper[Offline AI / C++]
    end
    
    subgraph Offline AI
        Whisper --> JNI[JNI Bridge]
        JNI --> CPP[Whisper.cpp Engine]
        CPP --> Model[GGML Model .bin]
    end
    
    Assets -- "Fast Read" --> Repo
    LocalDB -- "Persist Progress" --> Repo
```
While we started with **Nicobarese**—the heartbeat of the Nicobar Islands—our vision is far greater. We are building a digital ark for **all endangered tribal languages**. 

This isn't just an app. It's a bridge between generations. It helps teachers pass the language of our ancestors to students—so it is never lost.
---

## 🚀 Key Features

We combined detailed cultural preservation with cutting-edge tech:

*   **⚡ Offline-First Architecture:** Works completely without internet. Because culture shouldn't depend on connectivity.
*   **🗣️ Smart Pronunciation (TTS):** Customized Text-to-Speech engine acts as a digital guide for teachers.
*   **🌍 Community Hub:** A simulated social space for learners to share "Words of the Day" and challenges.
*   **🛡️ Admin & Teacher Modes:** specialized dashboards with role-based access control.
*   **🧠 Gamified Learning:** visual flashcards, streaks, and "Level Up" mechanics for students.
*   **🎨 Rive Animations:** Smooth, 60fps vector animations that make learning feel alive.
*   **🔌 Zero Latency Search:** Instant result lookup using optimized local JSON assets.

---

## 📸 Experience The App

### StartUp & Onboarding
<p align="center">
  <img src="github_readme_ss/app_language.png" width="22%" style="margin: 1%" />
  <img src="github_readme_ss/translate_language.png" width="22%" style="margin: 1%" />
  <img src="github_readme_ss/role_selector.png" width="22%" style="margin: 1%" />
  <img src="github_readme_ss/aboutus.png" width="22%" style="margin: 1%" />
</p>

### Role-Based Dashboards (Student vs Teacher)
<p align="center">
  <img src="github_readme_ss/student_dash.png" width="22%" style="margin: 1%" />
  <img src="github_readme_ss/teacher_dash.png" width="22%" style="margin: 1%" />
  <img src="github_readme_ss/bothway_translate.png" width="22%" style="margin: 1%" />
  <img src="github_readme_ss/bothway_translate2.png" width="22%" style="margin: 1%" />
</p>

### Interactive Learning Modules
<p align="center">
  <img src="github_readme_ss/numbers_page.png" width="22%" style="margin: 1%" />
  <img src="github_readme_ss/nature_page.png" width="22%" style="margin: 1%" />
  <img src="github_readme_ss/feelings_page.png" width="22%" style="margin: 1%" />
  <img src="github_readme_ss/mybody_page.png" width="22%" style="margin: 1%" />
</p>

---

## 🛠️ Installation & Setup

Want to run this locally? Follow these steps:

### Prerequisites
*   [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.0.0 or higher)
*   VS Code or Android Studio

### Steps
1.  **Clone the Repository**
    ```bash
    git clone https://github.com/sathiyatskrj/Speechmate.git
    cd Speechmate
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Run the App**
    ```bash
    flutter run
    ```

---

## 🔮 The Future: "Project Tribal-Link"

SpeechMate is the prototype engine. Our roadmap includes:

1.  **Multi-Dialect Support:** Expanding to **Onges, Great Andamanese etc**.
2.  **Voice Contribution:** Allowing elders to record pronunciations directly into the app to build a "Voice Archive".
3.  **AI Integration:** Using machine learning to translate full sentences from local dialects to English.

---
<p align="center">
  *Preserving the past, coding the future.*
</p>



