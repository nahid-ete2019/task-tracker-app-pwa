#!/usr/bin/env bash
# Vercel build step: Vercel's build image doesn't ship Flutter, so this
# script fetches the stable SDK, then builds the web release with the
# Supabase credentials passed in as Vercel Environment Variables
# (Project Settings > Environment Variables): SUPABASE_URL, SUPABASE_ANON_KEY.
set -euo pipefail

FLUTTER_DIR="$HOME/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

flutter config --enable-web
flutter pub get

flutter build web --release \
  --dart-define=SUPABASE_URL="${SUPABASE_URL:?SUPABASE_URL env var is not set in Vercel project settings}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:?SUPABASE_ANON_KEY env var is not set in Vercel project settings}"
