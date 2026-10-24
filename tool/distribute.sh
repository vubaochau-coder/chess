#!/bin/bash
set -e

# Configuration
PROJECT_ID="chess-app-chauvb"
APP_ID="1:540704428434:android:68a225d41ca53ba131b14b"
TESTERS="${TESTERS:-vubaochau001@gmail.com}"
RELEASE_NOTES="${1:-Bản build test mới}"

echo "=========================================="
echo "  Building release APK via FVM Flutter..."
echo "=========================================="
fvm flutter build apk --release

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [ ! -f "$APK_PATH" ]; then
  echo "Error: APK not found at $APK_PATH"
  exit 1
fi

echo "=========================================="
echo "  Uploading to Firebase App Distribution..."
echo "  Project: $PROJECT_ID"
echo "  App ID:  $APP_ID"
echo "  Testers: $TESTERS"
echo "  Notes:   $RELEASE_NOTES"
echo "=========================================="
npx -y firebase-tools@latest appdistribution:distribute "$APK_PATH" \
  --app "$APP_ID" \
  --testers "$TESTERS" \
  --release-notes "$RELEASE_NOTES" \
  --project "$PROJECT_ID"

echo "=========================================="
echo "  Distribution completed successfully!"
echo "=========================================="
