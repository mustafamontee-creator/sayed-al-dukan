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

# Flutter 3.38 generates Kotlin-DSL Gradle files. Keep the wrapper current.
python3 - <<'PY'
from pathlib import Path

wrapper = Path("android/gradle/wrapper/gradle-wrapper.properties")
lines = wrapper.read_text().splitlines()
for index, line in enumerate(lines):
    if line.startswith("distributionUrl="):
        lines[index] = "distributionUrl=https\\://services.gradle.org/distributions/gradle-8.14.3-bin.zip"
        break
else:
    raise SystemExit("Could not locate Gradle distributionUrl")
wrapper.write_text("\n".join(lines) + "\n")
PY

flutter pub get
dart run flutter_launcher_icons
echo "Setup done. Next: ./build_apk.sh"
