"""Configure Flutter's generated Gradle Kotlin DSL for release-key signing.

Run from the repository root after 'flutter create --platforms=android .'.
Private keystores and passwords must be injected by the CI runner.
"""
from pathlib import Path

gradle = Path("android/app/build.gradle.kts")
text = gradle.read_text(encoding="utf-8")
marker = '    buildTypes {'
assert marker in text, "Could not find buildTypes in generated Gradle file"
assert 'signingConfigs.getByName("debug")' in text, "Generated Flutter Gradle template changed; refusing unsigned fallback"

signing = '''
    signingConfigs {
        create("release") {
            storeFile = file(System.getenv("CROWN_KEYSTORE_FILE")
                ?: error("Missing CROWN_KEYSTORE_FILE"))
            storePassword = System.getenv("CROWN_STORE_PASSWORD")
                ?: error("Missing CROWN_STORE_PASSWORD")
            keyAlias = System.getenv("CROWN_KEY_ALIAS")
                ?: error("Missing CROWN_KEY_ALIAS")
            keyPassword = System.getenv("CROWN_KEY_PASSWORD")
                ?: error("Missing CROWN_KEY_PASSWORD")
        }
    }
'''
text = text.replace(marker, signing + '\n' + marker, 1)
text = text.replace(
    'signingConfig = signingConfigs.getByName("debug")',
    'signingConfig = signingConfigs.getByName("release")',
    1
)
gradle.write_text(text, encoding="utf-8")
print("Release signing configured from private environment variables.")
