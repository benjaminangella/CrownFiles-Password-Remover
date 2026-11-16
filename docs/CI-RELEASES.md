# Crown Password Studio: GitHub-only builds and signing

The owner does **not** need Android Studio. All builds are created on hosted GitHub Actions runners.

## Platforms

| Platform | GitHub runner | Initial artifact | Store signing |
| --- | --- | --- | --- |
| Android | Ubuntu | Debug APK | Requires a persistent release keystore; never use debug key for production |
| Windows | Windows | Unsigned desktop folder | Requires code-signing credentials to establish publisher identity |
| iOS / iPadOS | macOS | Unsigned simulator bundle | Requires Apple Developer membership, distribution certificate, provisioning profile |
| macOS | macOS | Unsigned desktop bundle | Requires Developer ID certificate and usually Apple notarization |
| Linux | Ubuntu | Desktop bundle | No universal OS-wide signing identity |
| Web | Ubuntu | Web folder | HTTPS hosting; no code-signing certificate |

## Release workflow

1. GitHub Actions builds all initial platform artifacts automatically on pushes to main.
2. Artifacts remain attached to each workflow run for 14 days.
3. Debug Android APK is for testing, not Play Store publishing.
4. Production release workflows must run only after test builds pass and the owner supplies the relevant certificates/keystores as **GitHub repository secrets**.
5. Apple builds for physical phones / App Store require Apple authorization. The iOS simulator build is not an IPA.
6. Do not upload signing keys in chat or commit them to source code.
7. Use GitHub environment approvals to separate test and production signing.

## Feature parity

Flutter application under `lib/` is the shared multiplatform source. The pre-existing Kotlin Android prototype remains under `app/` as a historical reference; its Android-only PDFBox implementation is not the shipping multiplatform engine. The shared PDF engine uses `pdf_manipulator` with cross-platform Rust binaries. File pickers handle native Android, Apple, Windows, Linux and web save/open dialogs.

Encrypted file-opening passwords require valid credentials; no guarantee of recovering unknown encryption passwords. Office formats are identified but their actual security handling is still planned.
