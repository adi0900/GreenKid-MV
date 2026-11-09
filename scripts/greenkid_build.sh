#!/bin/bash
# SPDX-License-Identifier: MIT
# Builds only from the player's files. No game data belongs in this repository.
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"
SOURCE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SUPPORT_DIR="${GREENKID_SUPPORT_DIR:-$HOME/Library/Application Support/GreenKid-MV}"

doctor() {
  [[ "$(uname -m)" == arm64 ]] || { echo 'Apple silicon is required.'; return 1; }
  command -v uv >/dev/null || { echo 'Install the prerequisite tools shown in the README (uv is missing).'; return 1; }
  command -v dotnet >/dev/null || { echo 'The .NET SDK is missing. See the README.'; return 1; }
  xcrun --find metal >/dev/null 2>&1 || { echo 'Install Xcode 27.2 and its Metal Toolchain, then open Xcode once.'; return 1; }
  for tool in xcodegen zstd glslangValidator; do
    command -v "$tool" >/dev/null || { echo "Missing prerequisite: $tool. See the README."; return 1; }
  done
}

case "${1:-}" in
  --doctor) doctor; echo 'Prerequisite executables found. Engine build performs the exact compiler-version check.'; exit 0 ;;
  --build) shift ;;
  *) echo 'Usage: greenkid_build.sh --doctor | --build <game-folder> [normal|performance]'; exit 2 ;;
esac
GAME_DIR="${1:?Choose a folder containing your own game dump}"
PRESET="${2:-normal}"
[[ "$PRESET" == normal || "$PRESET" == performance ]] || { echo 'Unknown resolution preset.'; exit 2; }
[[ -d "$GAME_DIR" ]] || { echo 'The game folder does not exist.'; exit 2; }
GAME_DIR="$(cd "$GAME_DIR" && pwd -P)"
if git -C "$GAME_DIR" rev-parse --show-toplevel >/dev/null 2>&1; then
  echo 'Choose a game folder outside a Git repository. Private game outputs must stay separate from source.'
  exit 2
fi
case "$GAME_DIR/" in "$SOURCE_ROOT/"*) echo 'Keep game files outside the builder source.'; exit 2;; esac
doctor
mkdir -p "$SUPPORT_DIR"
REVISION="$(tr -d '\r\n' < "$SOURCE_ROOT/UPSTREAM-REVISION")"
ENGINE_DIR="$SUPPORT_DIR/engine/$REVISION"
if [[ ! -f "$ENGINE_DIR/.copy-complete" ]]; then
  echo 'Preparing a writable copy of the included engine; the signed app remains unchanged.'
  mkdir -p "$ENGINE_DIR"
  /usr/bin/python3 "$SOURCE_ROOT/tools/copy_engine.py" "$SOURCE_ROOT" "$ENGINE_DIR"
  touch "$ENGINE_DIR/.copy-complete"
fi
PYTHON="$SUPPORT_DIR/venv/bin/python3"
if [[ ! -x "$PYTHON" ]]; then uv venv --python 3.14 --managed-python "$SUPPORT_DIR/venv"; fi
REQUIREMENTS_KEY="$(shasum -a 256 "$ENGINE_DIR/requirements-builder.txt" | cut -d ' ' -f 1)"
if [[ ! -f "$SUPPORT_DIR/requirements.key" ]] || [[ "$(cat "$SUPPORT_DIR/requirements.key")" != "$REQUIREMENTS_KEY" ]]; then
  uv pip install --python "$PYTHON" -r "$ENGINE_DIR/requirements-builder.txt"
  printf '%s\n' "$REQUIREMENTS_KEY" > "$SUPPORT_DIR/requirements.key"
fi
PRIVATE_DIR="$GAME_DIR/GreenKid-MV-local"
WORK_DIR="$PRIVATE_DIR/build"
OUTPUT_APP="$PRIVATE_DIR/Game.app"
mkdir -p "$PRIVATE_DIR"
BUILD_LOG="$PRIVATE_DIR/build.log"
printf 'Private outputs: %s\nEngine revision: %s\n' "$PRIVATE_DIR" "$REVISION"
cd "$ENGINE_DIR"
"$PYTHON" scripts/build_ipa_from_nsp.py "$GAME_DIR" --platform mac --work-dir "$WORK_DIR" --keep-extracted --progress lines 2>&1 | tee "$BUILD_LOG"
ENV_FILE="$PRIVATE_DIR/runtime.env"
printf '# Local settings for the app built from your dump\n' > "$ENV_FILE"
if grep -q 'game profile: 0400486024DEC000' "$BUILD_LOG"; then
  IMAGE="$WORK_DIR/extract/v131072/RomFS.img"
  [[ -f "$IMAGE" ]] || { echo 'The supported Ocarina of Time v131072 RomFS image was not found.'; exit 1; }
  "$PYTHON" scripts/oot_res_overlay.py "$IMAGE" "$WORK_DIR/extract/v131072/romfs_overlay/handheld" 0.666667 - flat
  "$PYTHON" scripts/oot_res_overlay.py "$IMAGE" "$WORK_DIR/extract/v131072/romfs_overlay/potato-handheld" 0.75 - flat
  cat >> "$ENV_FILE" <<'SETTINGS'
DM_FULLSCREEN=0
DM_OPMODE=0
DM_UPSCALER=metalfx
DM_FPS_HOLD=off
DM_TEX_RELEASE=0
DM_GUEST_FILE=0
DM_MEM_CAP_GB=13
DM_FOCUS_KEEP=1
SETTINGS
  if [[ "$PRESET" == performance ]]; then echo 'DM_RES_PRESET=1' >> "$ENV_FILE"; else echo 'DM_RES_PRESET=0' >> "$ENV_FILE"; fi
fi
"$PYTHON" scripts/build_ipa_from_nsp.py "$GAME_DIR" --platform mac-app --work-dir "$WORK_DIR" --keep-extracted --env-file "$ENV_FILE" -o "$OUTPUT_APP" --progress lines 2>&1 | tee -a "$BUILD_LOG"
printf '\nREADY: %s\nThis app contains your game. Keep it private; do not upload it.\n' "$OUTPUT_APP"
