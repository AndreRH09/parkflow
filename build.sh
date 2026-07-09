
#!/bin/bash
set -e

echo "Installing Flutter..."
cd /tmp
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:/tmp/flutter/bin"

echo "Configuring Flutter for web..."
flutter config --enable-web
flutter config --no-analytics

echo "Going back to project..."
cd $VERCEL_PROJECT_DIR

echo "Getting dependencies..."
flutter pub get

echo "Building web..."
flutter build web --release --no-tree-shake-icons

echo "Build completed!"