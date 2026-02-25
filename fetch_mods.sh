#!/usr/bin/env bash
set -euo pipefail

echo "== Fetching Mod Layers from Google Drive =="

# Google Drive file IDs
ATM_ID="1kJUtcaDFGDzzUJB6TPGLaVeMsJT2QqIt"
OVERRIDE_ID="1s_dNyvWBM4Q21NexxpekAfElJuJfyaY9"
TTS_ID="1SLPGok94eNuyi0ROlEUL71h-8dyjg1sO"

download_layer () {
    local name="$1"
    local file_id="$2"

    if [ -z "$file_id" ]; then
        echo "Skipping $name (no ID set)"
        return
    fi

    echo "Downloading $name..."
    gdown "https://drive.google.com/uc?id=${file_id}" -O "${name}.zip"

    rm -rf "$name"
    unzip -o "${name}.zip"
    rm "${name}.zip"
}

download_layer "mods.atm" "$ATM_ID"
download_layer "mods.override" "$OVERRIDE_ID"
download_layer "mods.tts" "$TTS_ID"

echo "Mod layers ready."
