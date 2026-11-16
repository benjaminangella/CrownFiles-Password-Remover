# CrownFiles: Password Remover — Crown Password Studio

Cross-platform Office and PDF security tools by AROSOFT Innovations Ltd.

## Development: GitHub Actions only

**No Android Studio or local Apple/Windows development setup is required from the owner.** The shared Flutter source is in `lib/`. GitHub Actions handles platform generation, analysis, tests, and packaging for:

- Android test APK (Ubuntu runner)
- Windows desktop (Windows runner)
- iOS/iPadOS simulator without signing (macOS runner)
- macOS desktop (macOS runner)
- Linux desktop (Ubuntu runner)
- Web (Ubuntu runner)

**Builds:** [Crown Studio | Cross-platform builds](https://github.com/benjaminangella/CrownFiles-Password-Remover/actions/workflows/flutter-multiplatform.yml)

**Signed Android releases:** [Signed Android release](https://github.com/benjaminangella/CrownFiles-Password-Remover/actions/workflows/android-signed-release.yml) — requires publisher-provided signing secrets in GitHub's protected `production` environment.

See [CI and signing guide](docs/CI-RELEASES.md).

## Current shared application

- Spacious, responsive Crown-themed UI with simple tools and file selection.
- Local PDF protection with AES-256, unlocking using a correct existing password, and password changes.
- Save processed PDFs under new filenames; keep original untouched.
- Basic PDF inspection.
- Local Word and Excel OOXML editing-protection inspection (including macro-enabled document detection).
- Create separate editable copies of unencrypted `.xlsx` / `.xlsm` / `.docx` / `.docm` documents where supported editing restrictions are found. Existing content and VBA binaries are preserved, with an output ZIP integrity check.
- Detect modern Office opening-password containers and identify unsupported legacy formats without claiming to decrypt them.
- Recognize PowerPoint file types; full PowerPoint protection processing remains under development.
- Shared file picker for mobile, desktop, and web.

## Security limitations

Strong opening-password encryption cannot be guaranteed to be removed without the correct password or another legitimate recovery method. This first implementation does not include forgotten-password cracking or bypass. Editing restrictions and opening-password encryption are distinct. Modern Office opening-password encryption, older binary Office formats, and VBA project-password recovery are **not** implemented in the shared Flutter engine. The original CrownFiles repository has separate Python desktop experiments, but they cannot automatically run in an Android application. Editing-restriction cleanup is not guaranteed to preserve all specialized Office extensions or digital signatures; test saved copies in Office before relying on them.

The previous Android-specific Kotlin proof of concept remains in `app/` for reference; the supported cross-platform implementation is in `lib/`. The native-only CI is manual.

## Release readiness

CI build success is not a guarantee of correct operation on physical devices. Signed release distributions require publisher certificates/keys, platform validation, privacy review and store testing. An iOS simulator build is **not** a signed IPA and cannot be distributed through the App Store.
