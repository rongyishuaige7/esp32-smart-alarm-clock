#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHONPYCACHEPREFIX="$(mktemp -d)"; export PYTHONPYCACHEPREFIX
PIO_WORK_DIR="$(mktemp -d)"
FLUTTER_BUILD_DIR="$ROOT/app/build"
FLUTTER_DART_TOOL="$ROOT/app/.dart_tool"
FLUTTER_PLUGIN_FILES=("$ROOT/app/.flutter-plugins" "$ROOT/app/.flutter-plugins-dependencies")
FLUTTER_GENERATED_PATHS=(
  "$ROOT/app/android/local.properties"
  "$ROOT/app/ios/Flutter/Generated.xcconfig"
  "$ROOT/app/ios/Flutter/flutter_export_environment.sh"
  "$ROOT/app/ios/Flutter/ephemeral"
  "$ROOT/app/macos/Flutter/ephemeral"
  "$ROOT/app/linux/flutter/ephemeral"
  "$ROOT/app/windows/flutter/ephemeral"
)
cleanup() {
  rm -rf -- "$PYTHONPYCACHEPREFIX" "$PIO_WORK_DIR" "$FLUTTER_BUILD_DIR" "$FLUTTER_DART_TOOL"
  rm -rf -- "${FLUTTER_GENERATED_PATHS[@]}"
  rm -f -- "${FLUTTER_PLUGIN_FILES[@]}"
}
trap cleanup EXIT

# These gates scan tracked files after Git initialization. Before then, they
# scan the working tree. Run them after cleanup so generated Flutter files
# cannot be mistaken for publication candidates.
python3 -m unittest discover -s "$ROOT/tests" -v
rsync -a --delete --exclude='.git/' --exclude='.pio/' "$ROOT/firmware/" "$PIO_WORK_DIR/"
pio run -d "$PIO_WORK_DIR"
(
  cd "$ROOT/app"
  flutter pub get
  flutter test
  flutter analyze
  flutter build web --release
)
cleanup
trap - EXIT
python3 "$ROOT/scripts/secret_scan.py" --root "$ROOT"
python3 "$ROOT/scripts/check_repo.py" --root "$ROOT"
echo 'Verification: PASS'
