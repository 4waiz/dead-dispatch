#!/usr/bin/env bash
# Dead Dispatch — Android release build.
#
# Produces a signed AAB suitable for Play Console upload.
# Prereqs:
#   - `android/key.properties` with keystore path + credentials
#   - `android/app/upload-keystore.jks` in place
# Neither is committed to git (see .gitignore).

set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Flutter doctor"
flutter doctor -v | sed 's/^/    /'

echo "==> Clean + pub get"
flutter clean
flutter pub get

echo "==> Analyze + test"
flutter analyze
flutter test

echo "==> Build app bundle (release)"
flutter build appbundle \
  --release \
  --dart-define=FLAVOR=release \
  --dart-define=ENABLE_ADS=true \
  --dart-define=ENABLE_ANALYTICS=true \
  --dart-define=DEBUG_TOOLS=false

echo
echo "==> Done. Output:"
ls -lh build/app/outputs/bundle/release/*.aab
