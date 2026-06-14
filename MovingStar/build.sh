#!/bin/bash
# Build script for MovingStar
# Requires NASM: https://www.nasm.us/

set -e

SRC="src/MovingStar.asm"
OUT="MovingStar.com"

echo "Assembling $SRC ..."
nasm -f bin "$SRC" -o "$OUT"
echo "Done! Output: $OUT"
echo ""
echo "To run: mount this folder in DOSBox and execute MovingStar.com"
