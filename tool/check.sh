#!/bin/sh
# Runs every automatic check: formatting, static analysis and tests.
set -e
cd "$(dirname "$0")/.."

echo "Formatting…"
dart format --output=none --set-exit-if-changed lib test

echo "Analysis…"
flutter analyze --fatal-infos

echo "Tests…"
flutter test

echo "All checks passed."
