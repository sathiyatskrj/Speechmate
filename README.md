# Speechmate

**Speechmate** is a simple prototype of a bilingual classroom assistant for tribal schools in the Nicobar region.

It demonstrates how teachers and children can use a single app to bridge the gap between the **school language (English)** and the **tribal language (Central Nicobarese)**.

This repository contains:

- Complete source code (open-source)
- Sample bilingual phrase data
- Architecture documentation
- Example test cases
- License information

---

## 1. Problem & Idea

In many tribal classrooms, young children speak only their **home / tribal language**, while teaching happens in **English or Hindi**.  
This leads to:

- Communication gaps between teacher and child  
- Loss of confidence and learning  
- Slow disappearance of the tribal language

**Speechmate** is a prototype that shows how a small app can:

- Help children **hear and see** words in **both** languages  
- Help teachers **give instructions** in school language and get the **tribal-language output** (text + audio in future versions)

---

## 2. Features (Demo version)

### Child Mode

- Big, colourful picture cards with emojis
- When a child taps a card:
  - Shows **English word/phrase**
  - Shows **Central Nicobarese equivalent**
  - (In a future version: plays recorded tribal audio)

### Teacher Mode

- Teacher types a command in **English** (e.g., `come here`, `water`)
- App looks it up in a small **offline phrase library**
- Shows the **Nicobarese phrase**
- Simulated “mic” button that cycles through demo phrases to represent a future speech-to-text feature

> Note: This is a **web-based prototype** (HTML + CSS + JavaScript), not a full Android APK. It is meant for **demonstration and video**.

---

## 3. Tech Stack

- **Frontend**:  
  - HTML5  
  - CSS3  
  - Vanilla JavaScript (ES6)

- **No backend / no server** (static site)
- **No build tools** required

---

## 4. Project Structure

```text
speechmate/
├─ index.html          # Single-page app: UI + logic
├─ data/
│  └─ phrases.json     # Sample English → Nicobarese phrase data
├─ tests/
│  └─ test_cases.md    # Manual test cases for demo validation
├─ README.md           # Project overview and setup
├─ ARCHITECTURE.md     # Architecture and design decisions
└─ LICENSE             # Open-source license (MIT)
