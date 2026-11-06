#!/bin/bash
# Streamed directly over SSH by the launcher. No scripts are stored on the pod.
set -euo pipefail

WORKSPACE="${WORKSPACE:-/workspace}"
# Keep in sync with REMOTE_STUDIO_DIR in crates/launcher/src/ssh.rs.
STUDIO_DIR="${WORKSPACE}/ace-step-studio"
BIN_DIR="${STUDIO_DIR}/bin"
ENGINE_DIR="${BIN_DIR}/resources/engine"
MIDI_DIR="${BIN_DIR}/resources/music-midi"
DATA_DIR="${STUDIO_DIR}/data"

# 1. Ensure studio directories exist
mkdir -p "$BIN_DIR" "$DATA_DIR" "$ENGINE_DIR" "$MIDI_DIR"

# 2. Check binaries exist
if [ ! -f "${BIN_DIR}/music-server" ] || [ ! -f "${ENGINE_DIR}/ace-server" ]; then
    echo "[ERROR] Binaries not found in ${BIN_DIR}. Push them from the launcher with 'p' first." >&2
    exit 1
fi

chmod +x "${BIN_DIR}/music-server" "${ENGINE_DIR}/ace-server" 2>/dev/null || true
chmod +x "${MIDI_DIR}/music-midi" "${MIDI_DIR}/music-caption" 2>/dev/null || true

# 3. Stop any existing server processes cleanly
pkill -9 -x "music-server" 2>/dev/null || true
pkill -9 -x "ace-server" 2>/dev/null || true
sleep 1

# 4. Configure Environment
export LD_LIBRARY_PATH="${ENGINE_DIR}:${MIDI_DIR}:${BIN_DIR}:${LD_LIBRARY_PATH:-}"
export PATH="${BIN_DIR}:${PATH}"

export STUDIO_DATA_ROOT="$DATA_DIR"
export STUDIO_ENGINE_ROOT="$ENGINE_DIR"
export STUDIO_ENGINE_BIN="${ENGINE_DIR}/ace-server"
export STUDIO_PORT="8792"

# 5. Start music-server in background
nohup "${BIN_DIR}/music-server" > "${STUDIO_DIR}/ace-step-studio.log" 2>&1 </dev/null &
PID=$!
disown -a 2>/dev/null || true
echo "[ok] ACE-Step Studio remote daemon started (PID: $PID)."
