#!/usr/bin/env bash
# Usage: SUPABASE_URL=... SUPABASE_PUBLISHABLE_KEY=... plus Android signing env vars.
set -euo pipefail
cd "$(dirname "$0")"
: "${SUPABASE_URL:?set SUPABASE_URL}" "${SUPABASE_PUBLISHABLE_KEY:?set SUPABASE_PUBLISHABLE_KEY}"
: "${ANDROID_KEYSTORE_PASSWORD:?set ANDROID_KEYSTORE_PASSWORD}"
export ANDROID_KEY_PASSWORD="${ANDROID_KEY_PASSWORD:-$ANDROID_KEYSTORE_PASSWORD}"
export ANDROID_KEY_ALIAS="${ANDROID_KEY_ALIAS:-sayed-al-dukan-release}"
if [[ -n "${ANDROID_KEYSTORE_BASE64:-}" ]]; then
  printf '%s' "$ANDROID_KEYSTORE_BASE64" | base64 --decode > android/app/release-key.p12
  export ANDROID_KEYSTORE_PATH="$PWD/android/app/release-key.p12"
else
  : "${ANDROID_KEYSTORE_PATH:?set ANDROID_KEYSTORE_PATH or ANDROID_KEYSTORE_BASE64}"
fi
DEFINES=(--dart-define=SUPABASE_URL="$SUPABASE_URL" --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY")
flutter analyze --no-fatal-infos
flutter test
flutter build apk --release "${DEFINES[@]}"
echo "APK: build/app/outputs/flutter-apk/app-release.apk"
