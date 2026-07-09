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
cd "$OLDPWD"

echo "Project directory: $(pwd)"
echo "Checking for pubspec.yaml:"
ls -la pubspec.yaml

echo "Getting dependencies..."
flutter pub get

# Validar que las variables requeridas estén presentes
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
  echo "Missing required environment variables: SUPABASE_URL and SUPABASE_ANON_KEY"
  exit 1
fi

echo "Building web with environment variables..."
flutter build web \
  --release \
  --no-tree-shake-icons \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=GOOGLE_WEB_CLIENT_ID="${GOOGLE_WEB_CLIENT_ID:-}"

echo "✅ Build completed!"