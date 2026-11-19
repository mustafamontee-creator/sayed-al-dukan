#!/usr/bin/env bash
# One-time setup: generates Android/iOS folders around the existing sources.
set -euo pipefail
cd "$(dirname "$0")"
command -v flutter >/dev/null || { echo "Install Flutter first: https://docs.flutter.dev/get-started/install"; exit 1; }
tmp=$(mktemp -d)
cp -r lib test assets docs supabase tools pubspec.yaml analysis_options.yaml README.md firebase "$tmp"/
flutter create --platforms=android,ios --org com.sayedaldukan --project-name sayed_al_dukan .
rm -rf lib test && cp -r "$tmp/lib" "$tmp/test" .
cp "$tmp/pubspec.yaml" "$tmp/analysis_options.yaml" "$tmp/README.md" .
mkdir -p android/app
cp "$tmp/firebase/google-services.json" android/app/google-services.json
python3 tools/patch_android.py

# Configure repository mirrors to reduce Maven Central rate-limit failures.
python3 - <<'PY'
from pathlib import Path
p = Path('android/settings.gradle.kts')
s = p.read_text()
mirror = 'maven { url = uri("https://maven.aliyun.com/repository/central") }'

# Add the mirror to plugin-management repositories.
start = s.find('pluginManagement {')
if start >= 0:
    end = s.find('}', start)
    block = s[start:end]
    if mirror not in block:
        s = s[:start] + s[start:].replace('repositories {', 'repositories {\n        ' + mirror, 1)

if 'gradlePluginPortal()' not in s:
    s = s.replace('repositories {', 'repositories {\n        gradlePluginPortal()', 1)

# Ensure dependency repositories also include the mirror.
if 'dependencyResolutionManagement {' not in s:
    s += '\ndependencyResolutionManagement {\n    repositories {\n        google()\n        ' + mirror + '\n        mavenCentral()\n    }\n}\n'
else:
    start = s.find('dependencyResolutionManagement {')
    if mirror not in s[start:]:
        s = s[:start] + s[start:].replace('repositories {', 'repositories {\n        ' + mirror, 1)

p.write_text(s)
PY

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
