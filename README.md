# CrownFiles: Password Remover — Crown Password Studio

An Android-first, offline Office/PDF file security application by AROSOFT Innovations Ltd.

## First implementation (0.1.0)

- Minimal, spacious native Jetpack Compose UI with Crown navy, gold, and clean white cards.
- Android system file selection and save-as-new-file workflow; no broad storage permission.
- PDF password protection, unlocking with a **valid existing password**, and password changes.
- Local processing using PDFBox Android. The source file is never overwritten.
- Detects common Word, Excel, PowerPoint and PDF extensions, and clearly identifies Office workflows as upcoming (not falsely advertised as complete).
- Passwords are held only in UI memory during the action and cleared on completion/cancellation. No analytics, ads, or network permission.

## Important limitations

Strongly encrypted files cannot be guaranteed to open without a valid password. No cracking, brute-force, bypass, or unknown-password removal is implemented. `Unlock` requires the current password. PDF permissions and Office worksheet protection are not equivalent to file-opening encryption.

PDFBox Android compatibility may differ across PDF encryption revisions; test with known fixtures. PDFBox uses the owner/user passwords as set by this first version. Future builds can introduce separate owner-password controls and stronger file validation.

Office encryption and sheet/workbook protection need their own tested implementation. VBA protection is not supported in this first release.

## Build

Open this project in Android Studio with JDK 17 and Android SDK 35. Sync Gradle, then run the `app` module on Android 8.0+.

> A source-code foundation, not a published APK. Debug and release builds, device testing, and Play policy review are still required.

## Roadmap

1. Test PDF inputs: unprotected, known-password encrypted, wrong password, and corrupted files.
2. Add secure password entry and explicit per-format feature support.
3. Implement supported Office protections and formats with regression tests.
4. Add batch operations, accessibility QA, privacy documentation, signing, and Play release workflow.
