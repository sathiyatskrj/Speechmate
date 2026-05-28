# Contributing to SpeechMate

Thank you for your interest in contributing to SpeechMate! This project preserves endangered Nicobarese and Great Andamanese languages, and every contribution helps keep these languages alive in the digital world.

## Table of Contents

- [Getting Started](#getting-started)
- [Branch Structure](#branch-structure)
- [Development Setup](#development-setup)
- [How to Contribute](#how-to-contribute)
- [Pull Request Process](#pull-request-process)
- [Code Style](#code-style)
- [Indigenous Data Guidelines](#indigenous-data-guidelines)
- [Reporting Issues](#reporting-issues)

---

## Getting Started

1. **Fork** the repository
2. **Clone** your fork locally
3. **Create a branch** for your feature or fix
4. **Make your changes** and test them
5. **Submit a Pull Request**

## Branch Structure

> ⚠️ **Critical: Never cross-commit between branches!**

| Branch | Edition | Audience | What belongs here |
| :--- | :--- | :--- | :--- |
| `main` | Institutional Edition | Teachers & Students | Student/Teacher dashboards, classroom management, gamification |
| `speechmate_general` | Explorer Edition | Travelers & Public | Explorer dashboard, off-grid features, keyboard, travel tools |

**Rules:**
- Teacher Dashboard and Student Dashboard features go to `main` **only**
- Explorer-specific features (Situational Phrasebook, Conversation Mode) go to `speechmate_general` **only**
- Shared core features (translation engine, Whisper STT, dictionaries) should be developed on the appropriate branch and then synced

## Development Setup

### Prerequisites

- Flutter 3.29+
- Dart 3.2+
- Android SDK 34+
- Android NDK 27
- Git LFS (for Whisper model)

### Setup

```bash
# Clone the repository
git clone https://github.com/sathiyatskrj/Speechmate.git
cd Speechmate

# Install Flutter dependencies
flutter pub get

# Pull large files (Whisper model)
git lfs pull

# Run the app
flutter run

# Run tests
flutter test
```

## How to Contribute

### 🐛 Bug Fixes
- Check existing [issues](https://github.com/sathiyatskrj/Speechmate/issues) first
- Create a branch: `fix/short-description`
- Include steps to reproduce in your PR

### ✨ New Features
- Open an issue first to discuss the feature
- Create a branch: `feature/short-description`
- Ensure the feature belongs on the correct branch (see Branch Structure above)

### 📝 Documentation
- Improvements to README, wiki, or inline comments are always welcome
- Create a branch: `docs/short-description`

### 🌐 Translations
- Help translate the app UI into additional languages
- Help validate or correct existing Nicobarese/Great Andamanese dictionary entries
- See [Indigenous Data Guidelines](#indigenous-data-guidelines) before contributing linguistic data

### 🧪 Testing
- Add unit tests for untested services
- Test on physical Android devices (especially Whisper STT flow)
- Report device-specific issues with full device specs

## Pull Request Process

1. **Update documentation** if your change affects public APIs or user-facing features
2. **Run all tests** before submitting: `flutter test`
3. **Run the analyzer**: `flutter analyze`
4. **Target the correct branch** — `main` for institutional features, `speechmate_general` for explorer features
5. **Write a clear PR description** explaining what changed and why
6. **Request review** from a maintainer
7. PRs require at least 1 approving review before merge

### Commit Message Convention

```
type(scope): short description

Examples:
feat(student): add new vocabulary category for marine life
fix(whisper): resolve crash on Snapdragon 4xx devices
docs(readme): update installation instructions for v1.5.0
build(android): bump targetSdk to 35
test(translation): add unit tests for fuzzy matching stage
```

## Code Style

- Follow the [Dart style guide](https://dart.dev/effective-dart/style)
- Use `flutter analyze` to check for issues
- Keep widgets focused and reusable
- Add doc comments to public classes and methods
- Preserve existing comments and documentation unless they're incorrect

## Indigenous Data Guidelines

SpeechMate contains linguistic data from **critically endangered languages**. Contributing linguistic data requires extra care:

### ✅ Acceptable Contributions
- Corrections to existing dictionary entries (with source/evidence)
- New vocabulary entries with proper attribution
- Audio recordings with explicit consent from the speaker
- Cultural content reviewed by community members

### ❌ Not Acceptable
- Unverified or machine-generated translations
- Data scraped from other sources without permission
- Content that violates tribal council protocols
- Data intended for commercial use or AI/LLM training

### Licensing
- All code contributions are licensed under **Apache 2.0**
- All linguistic data contributions are licensed under **CC BY-NC 4.0** with Traditional Knowledge (TK) protocols
- By contributing, you agree to these terms

## Reporting Issues

### Bug Reports
- Use the [Bug Report template](https://github.com/sathiyatskrj/Speechmate/issues/new?template=bug_report.md)
- Include: device model, Android version, steps to reproduce, expected vs actual behavior

### Feature Requests
- Use the [Feature Request template](https://github.com/sathiyatskrj/Speechmate/issues/new?template=feature_request.md)
- Explain the use case and which branch/edition it applies to

### Security Vulnerabilities
- See [SECURITY.md](SECURITY.md) for responsible disclosure

---

Thank you for helping preserve the languages of the Andaman & Nicobar Islands! 🌴
