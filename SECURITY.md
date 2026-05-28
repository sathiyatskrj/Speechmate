# Security Policy

## Supported Versions

| Version | Supported |
| :--- | :---: |
| 1.5.x | ✅ Active |
| < 1.5.0 | ❌ Not supported |

## Reporting a Vulnerability

If you discover a security vulnerability in SpeechMate, please report it responsibly.

### How to Report

1. **Do NOT open a public GitHub issue** for security vulnerabilities
2. Instead, please report via [GitHub Private Vulnerability Reporting](https://github.com/sathiyatskrj/Speechmate/security/advisories/new)
3. Alternatively, contact the maintainer directly through GitHub

### What to Include

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### Response Timeline

| Action | Timeline |
| :--- | :--- |
| Acknowledgment of report | Within 48 hours |
| Initial assessment | Within 1 week |
| Fix development | Within 2 weeks |
| Public disclosure (after fix) | Coordinated with reporter |

## Security Architecture

SpeechMate is designed with security as a core principle:

### Data Privacy
- **100% offline operation** — no user data is ever transmitted to external servers
- **No cloud services** — all translation, STT, and OCR processing happens on-device
- **No analytics or tracking** — zero telemetry
- **No account system** — no personal data collected

### On-Device Security
- **AES-GCM encryption** available for sensitive local data
- **Android Keystore (TEE)** integration for key management
- **ChaCha20 stream cipher** for mesh sync encryption
- **Ed25519 signatures** for data integrity verification

### Dependency Security
- Dependencies are pinned to specific versions in `pubspec.yaml`
- Native dependencies (NDK, CMake) are version-locked
- ML Kit models are bundled (not downloaded from untrusted sources)

## Known Limitations

- The app uses `signingConfig signingConfigs.debug` in development builds — production releases must use a proper release keystore
- Whisper model is downloaded over HTTPS on first launch — ensure the download URL is validated
- Mesh Sync (CRDT) and Bat-Sync features use experimental encryption — not yet audited for production security

## Scope

This security policy covers:
- ✅ The SpeechMate Android application
- ✅ All code in this repository
- ✅ Build and CI/CD pipeline security

This security policy does **not** cover:
- ❌ Third-party dependencies (report to their maintainers)
- ❌ The GitHub wiki (not security-critical)
