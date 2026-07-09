#!/bin/bash
set -e

echo "=== Starting Flutter Build ==="
echo "Current directory: $(pwd)"
echo "Contents:"
ls -la

# Instalar Flutter en /opt (no /tmp)
echo "Installing Flutter..."
mkdir -p /opt
cd /opt
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:/opt/flutter/bin"

flutter config --enable-web
flutter config --no-analytics

# Volver al directorio del proyecto (la raíz)
echo "Returning to project root..."
cd $OLDPWD

echo "Project directory: $(pwd)"
echo "Checking for pubspec.yaml:"
ls -la pubspec.yaml

echo "Getting dependencies..."
flutter pub get

echo "Building web..."
flutter build web --release --no-tree-shake-icons

echo "✅ Build completed!"