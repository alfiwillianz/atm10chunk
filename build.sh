#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

echo "== ATM Layered Merge System =="

# Priority order (low → high)
LAYERS=("atm" "tts" "override")

# Target folders to build
TARGETS=("mods" "config" "kubejs" "defaultconfigs" "datapacks" "local")

# Clean build dirs
for target in "${TARGETS[@]}"; do
    rm -rf "$target"
    mkdir -p "$target"
done

########################################
# FAST modId extractor (zipgrep-based)
########################################

extract_modid() {
    zipgrep -h 'modId *= *"' "$1" META-INF/*mods.toml 2>/dev/null \
        | head -n1 \
        | awk -F'"' '{print $2}'
}

########################################
# SERVER MOD MERGE (priority enforced)
########################################

declare -A MODIDS

merge_mod_layer() {
    local folder="$1"
    [ -d "$folder" ] || return

    echo "Applying $folder..."

    for jar in "$folder"/*.jar; do
        [ -f "$jar" ] || continue

        modid=$(extract_modid "$jar")

        if [ -z "$modid" ]; then
            echo "⚠ modId not found in $(basename "$jar") — copying anyway"
            cp -f "$jar" mods/
            continue
        fi

        # If already present, remove older version (priority wins)
        if [ -n "${MODIDS[$modid]+x}" ]; then
            rm -f "mods/$(basename "${MODIDS[$modid]}")"
        fi

        cp -f "$jar" mods/
        MODIDS["$modid"]="$jar"
    done
}

echo "Merging server mods..."

for layer in "${LAYERS[@]}"; do
    case "$layer" in
        atm) merge_mod_layer "mods.atm" ;;
        tts) merge_mod_layer "mods.tts" ;;
        override) merge_mod_layer "mods.override" ;;
    esac
done

########################################
# GENERIC FOLDER MERGE (priority overwrite)
########################################

merge_folder_layer() {
    local target="$1"
    local source="$2"
    [ -d "$source" ] || return
    cp -rT "$source" "$target"
}

echo "Merging configs and data..."

for layer in "${LAYERS[@]}"; do
    for target in config kubejs defaultconfigs datapacks local; do
        case "$layer" in
            atm) merge_folder_layer "$target" "$target.atm" ;;
            tts) merge_folder_layer "$target" "$target.tts" ;;
            override) merge_folder_layer "$target" "$target.override" ;;
        esac
    done
done

echo "Server merge complete."

########################################
# CLIENT MOD DELTA
# (mods.atm ∪ mods.override) − mods.tts
########################################

echo "Building client-only mod delta..."

rm -rf mods.client
mkdir -p mods.client

declare -A TTS_MODIDS
declare -A CLIENT_MODIDS

# Collect TTS modIds
if [ -d "mods.tts" ]; then
    for jar in mods.tts/*.jar; do
        [ -f "$jar" ] || continue
        modid=$(extract_modid "$jar")
        [ -n "$modid" ] && TTS_MODIDS["$modid"]=1
    done
fi

add_client_delta() {
    local folder="$1"
    [ -d "$folder" ] || return

    for jar in "$folder"/*.jar; do
        [ -f "$jar" ] || continue
        modid=$(extract_modid "$jar")
        [ -z "$modid" ] && continue

        if [ -z "${TTS_MODIDS[$modid]+x}" ]; then
            if [ -z "${CLIENT_MODIDS[$modid]+x}" ]; then
                cp -f "$jar" mods.client/
                CLIENT_MODIDS["$modid"]=1
            fi
        fi
    done
}

add_client_delta "mods.atm"
add_client_delta "mods.override"

echo "Client delta built."
echo "== Build complete =="
