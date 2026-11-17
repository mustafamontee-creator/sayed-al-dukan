#!/usr/bin/env bash
# Usage:
#   SUPABASE_URL=... SUPABASE_PUBLISHABLE_KEY=... ./build_apk.sh
set -euo pipefail
cd "$(dirname "$0")"
: "${SUPABASE_URL:?set SUPABASE_URL}" "${SUPABASE_PUBLISHABLE_KEY:?set SUPABASE_PUBLISHABLE_KEY}"
DEFINES=(--dart-define=SUPABASE_URL="$SUPABASE_URL" --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY")
flutter analyze
flutter test
flutter build apk --release "${DEFINES[@]}"
echo "APK: build/app/outputs/flutter-apk/app-release.apk"
