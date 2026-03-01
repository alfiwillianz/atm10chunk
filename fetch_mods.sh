#!/usr/bin/env bash
set -euo pipefail

echo "== Fetching Base Modpack =="
BASE_URL="https://www.curseforge.com/api/v1/mods/1298402/files/7674266/download"

echo "Downloading base modpack..."
curl -L "$BASE_URL" -o base.zip

echo "Extracting base modpack (config, defaultconfigs, kubejs, mods)..."
unzip -o base.zip "config/*" "defaultconfigs/*" "kubejs/*" "mods/*"
rm base.zip

echo "== Fetching Mod Layers from Google Drive =="

OVERRIDE_ID="1_oMG-4BtxyytzR_bthrDbEAAOF-JKlbC"

download_layer () {
    local name="$1"
    local folder_id="$2"

    if [ -z "$folder_id" ]; then
        echo "Skipping $name (no ID set)"
        return
    fi

    echo "Downloading $name folder..."
    rm -rf "$name"
    gdown --folder "https://drive.google.com/drive/folders/${folder_id}" -O "$name"
}

download_layer "mods.override" "$OVERRIDE_ID"

echo "Mod layers ready."
