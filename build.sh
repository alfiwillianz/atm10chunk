#!/usr/bin/env bash
set -euo pipefail

echo "== ATM Layered Merge System =="

# Priority order (low → high)
LAYERS=("atm" "tts" "override")

# Target folders to build
TARGETS=("mods" "config" "kubejs" "defaultconfigs" "datapacks" "local")

# Helper: clean build dirs
for target in "${TARGETS[@]}"; do
    rm -rf "$target"
    mkdir -p "$target"
done

########################################
# MOD MERGE (modId-aware)
########################################

declare -A MODIDS

extract_modid() {
    unzip -p "$1" META-INF/*mods.toml 2>/dev/null \
        | grep -m1 'modId' \
        | sed -E 's/.*modId="([^"]+)".*/\1/' \
        || true
}

merge_mod_layer() {
    local folder="$1"

    [ -d "$folder" ] || return

    for jar in "$folder"/*.jar; do
        [ -f "$jar" ] || continue

        modid=$(extract_modid "$jar")

        if [ -z "$modid" ]; then
            echo "modid not found! please check them manually $jar"
            cp -f "$jar" mods/
            continue
        fi

        # override behavior: always replace if already exists
        if [[ "$folder" == *".override" ]]; then
            cp -f "$jar" mods/
            MODIDS["$modid"]=1
            continue
        fi

        # normal behavior: only add if not present
        if [ -z "${MODIDS[$modid]+x}" ]; then
            cp "$jar" mods/
            MODIDS["$modid"]=1
        fi
    done
}

echo "Merging mods..."

for layer in "${LAYERS[@]}"; do
    case "$layer" in
        base) merge_mod_layer "mods" ;;
        atm) merge_mod_layer "mods.atm" ;;
        tts) merge_mod_layer "mods.tts" ;;
        override) merge_mod_layer "mods.override" ;;
    esac
done

########################################
# GENERIC FOLDER MERGE (overwrite-safe)
########################################

merge_folder_layer() {
    local target="$1"
    local source="$2"

    [ -d "$source" ] || return 0

    cp -rT "$source" "$target"
}

echo "Merging configs and data..."

for layer in "${LAYERS[@]}"; do
    for target in "${TARGETS[@]}"; do
        case "$layer" in
            base)
                merge_folder_layer "$target" "$target"
                ;;
            atm)
                merge_folder_layer "$target" "$target.atm"
                ;;
            tts)
                merge_folder_layer "$target" "$target.tts"
                ;;
            override)
                merge_folder_layer "$target" "$target.override"
                ;;
        esac
    done
done

echo "Merge complete."

########################################
# CLIENT MODS: (mods.atm ∪ mods.override) − mods.tts
########################################

echo "Building client mods..."

rm -rf mods.client
mkdir -p mods.client

# Collect modIds present in mods.tts
declare -A TTS_MODIDS
if [ -d "mods.tts" ]; then
    for jar in mods.tts/*.jar; do
        [ -f "$jar" ] || continue
        modid=$(extract_modid "$jar")
        [ -n "$modid" ] && TTS_MODIDS["$modid"]=1
    done
fi

# Add mods from mods.atm that are not in mods.tts
declare -A CLIENT_MODIDS
if [ -d "mods.atm" ]; then
    for jar in mods.atm/*.jar; do
        [ -f "$jar" ] || continue
        modid=$(extract_modid "$jar")
        if [ -z "$modid" ]; then
            echo "modid not found in $jar, please check manually"
            cp -f "$jar" mods.client/
            continue
        fi
        if [ -z "${TTS_MODIDS[$modid]+x}" ]; then
            cp "$jar" mods.client/
            CLIENT_MODIDS["$modid"]=1
        fi
    done
fi

# Add/replace mods from mods.override that are not in mods.tts
if [ -d "mods.override" ]; then
    for jar in mods.override/*.jar; do
        [ -f "$jar" ] || continue
        modid=$(extract_modid "$jar")
        if [ -z "$modid" ]; then
            echo "modid not found in $jar, please check manually"
            cp -f "$jar" mods.client/
            continue
        fi
        if [ -z "${TTS_MODIDS[$modid]+x}" ]; then
            cp -f "$jar" mods.client/
            CLIENT_MODIDS["$modid"]=1
        fi
    done
fi

echo "Client mods built."
