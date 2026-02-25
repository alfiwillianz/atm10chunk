#!/usr/bin/env bash
set -euo pipefail

echo "== Packaging Mod Layers =="

LAYERS=("mods.atm" "mods.tts" "mods.override")

mkdir -p dist

for layer in "${LAYERS[@]}"; do
    if [ -d "$layer" ]; then
        echo "Zipping $layer ..."
        zip -r "dist/${layer}.zip" "$layer"
    else
        echo "Skipping $layer (not found)"
    fi
done

echo "Done. Artifacts in ./dist/"
