#!/usr/bin/env bash
set -euo pipefail

echo "== Fetching Mod Layers from Google Drive =="

# Replace these with your actual Drive file IDs
ATM_ID="PASTE_ATM_FILE_ID"
TTS_ID="PASTE_TTS_FILE_ID"
OVERRIDE_ID="PASTE_OVERRIDE_FILE_ID"

download_layer () {
    local name="$1"
    local file_id="$2"

    if [ -z "$file_id" ]; then
        echo "Skipping $name (no ID set)"
        return
    fi

    echo "Downloading $name ..."
    gdown "https://drive.google.com/uc?id=${file_id}" -O "${name}.zip"

    rm -rf "$name"
    unzip -o "${name}.zip"
    rm "${name}.zip"
}

download_layer "mods.atm" "$ATM_ID"
download_layer "mods.tts" "$TTS_ID"
download_layer "mods.override" "$OVERRIDE_ID"

echo "Mod layers ready."
