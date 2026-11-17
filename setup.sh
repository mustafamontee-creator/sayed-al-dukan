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

settings = Path("android/settings.gradle")
content = settings.read_text()
for marker, version in (
    ('id "com.android.application" version "', "8.12.0"),
    ('id "org.jetbrains.kotlin.android" version "', "2.2.0"),
):
    if marker not in content:
        raise SystemExit(f"Could not locate plugin declaration: {marker}")
    start = content.index(marker) + len(marker)
    end = content.index('"', start)
    content = content[:start] + version + content[end:]
settings.write_text(content)

wrapper = Path("android/gradle/wrapper/gradle-wrapper.properties")
lines = wrapper.read_text().splitlines()
found = False
for index, line in enumerate(lines):
    if line.startswith("distributionUrl="):
        lines[index] = "distributionUrl=https\\://services.gradle.org/distributions/gradle-8.14.3-bin.zip"
        found = True
        break
if not found:
    raise SystemExit("Could not locate Gradle distributionUrl")
wrapper.write_text("\n".join(lines) + "\n")
PY

flutter pub get
dart run flutter_launcher_icons
echo "Setup done. Next: ./build_apk.sh"
