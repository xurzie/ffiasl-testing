#!/usr/bin/env bash
set -euo pipefail

VENDOR_DIR="third_party/ffiasm_upstream"
rm -rf "$VENDOR_DIR"
mkdir -p "$VENDOR_DIR"

TMP_DIR=".ffiasm-tmp"
rm -rf "$TMP_DIR"
git clone --depth 1 --filter=blob:none --sparse https://github.com/iden3/ffiasm.git "$TMP_DIR"
git -C "$TMP_DIR" sparse-checkout set c test

mkdir -p "$VENDOR_DIR/c" "$VENDOR_DIR/test"
rsync -a "$TMP_DIR/c/" "$VENDOR_DIR/c/"
rsync -a "$TMP_DIR/test/" "$VENDOR_DIR/test/"

cp "$TMP_DIR/COPYING" "$VENDOR_DIR/COPYING" || true

rm -rf "$TMP_DIR"

echo "[OK] ffiasm c/ и test/ синхронизированы в $VENDOR_DIR"
