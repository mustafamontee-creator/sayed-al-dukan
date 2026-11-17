#!/usr/bin/env bash
# One-time setup: generates android/ios folders around the existing sources.
set -euo pipefail
cd "$(dirname "$0")"
command -v flutter >/dev/null || { echo "Install Flutter first: https://docs.flutter.dev/get-started/install"; exit 1; }
tmp=$(mktemp -d)
cp -r lib test assets docs supabase tools pubspec.yaml analysis_options.yaml README.md "$tmp"/
flutter create --platforms=android,ios --org com.sayedaldukan --project-name sayed_al_dukan .
rm -rf lib test && cp -r "$tmp/lib" "$tmp/test" .
cp "$tmp/pubspec.yaml" "$tmp/analysis_options.yaml" "$tmp/README.md" .
python3 tools/patch_android.py

# Keep the Android toolchain compatible with app_links 6.4.1.
python3 - <<'PY'
from pathlib import Path
import re

settings = Path("android/settings.gradle")
if settings.exists():
    content = settings.read_text()
    content, agp_count = re.subn(
        r'(id ["\\']com\\.android\\.application["\\'] version ["\\'])[^"\\']+(["\\'] apply false)',
        r'\\g<1>8.12.0\\g<2>',
        content,
    )
    content, kotlin_count = re.subn(
        r'(id ["\\']org\\.jetbrains\\.kotlin\\.android["\\'] version ["\\'])[^"\\']+(["\\'] apply false)',
        r'\\g<1>2.2.0\\g<2>',
        content,
    )
    if agp_count == 0:
        raise SystemExit("Could not locate Android Gradle Plugin version in android/settings.gradle")
    if kotlin_count == 0:
        raise SystemExit("Could not locate Kotlin plugin version in android/settings.gradle")
    settings.write_text(content)

wrapper = Path("android/gradle/wrapper/gradle-wrapper.properties")
if wrapper.exists():
    content = wrapper.read_text()
    content, count = re.subn(
        r'^distributionUrl=.*$',
        'distributionUrl=https\\://services.gradle.org/distributions/gradle-8.14.3-bin.zip',
        content,
        flags=re.MULTILINE,
    )
    if count == 0:
        raise SystemExit("Could not locate Gradle distributionUrl")
    wrapper.write_text(content)
PY

flutter pub get
dart run flutter_launcher_icons
echo "Setup done. Next: ./build_apk.sh"
