#!/bin/bash
set -e

echo "Installing Flutter..."
cd /tmp
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:/tmp/flutter/bin"

flutter config --enable-web
flutter config --no-analytics

echo "Project directory: $VERCEL_PROJECT_DIR"
cd "$VERCEL_PROJECT_DIR"

echo "Current directory: $(pwd)"
echo "Checking pubspec.yaml: $(ls -la pubspec.yaml)"

echo "Getting dependencies..."
flutter pub get

echo "Building web..."
flutter build web --release --no-tree-shake-icons

echo "✅ Build completed!"