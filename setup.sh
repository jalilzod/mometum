#!/usr/bin/env bash
# One-time setup for macOS / Linux.
set -e
cd "$(dirname "$0")"
echo "▶ Generating Android & iOS platform folders..."
flutter create . --org com.momentum --project-name momentum --platforms=android,ios
echo "▶ Installing packages..."
flutter pub get
echo "▶ Patching platform config for notifications..."
dart run tool/setup.dart
echo ""
echo "Done! Connect a phone or start an emulator, then run:  flutter run"
