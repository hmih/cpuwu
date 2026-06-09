#!/usr/bin/env bash
# Download OSS CAD Suite into vendor/oss-cad-suite
# One-time setup for GateMate FPGA toolchain.
set -euo pipefail

OS=$(uname -s)
ARCH=$(uname -m)

case "$OS-$ARCH" in
  Darwin-arm64)  FILE="oss-cad-suite-darwin-arm64-20260530.tgz" ;;
  Darwin-x86_64) FILE="oss-cad-suite-darwin-x64-20260530.tgz"   ;;
  Linux-x86_64)  FILE="oss-cad-suite-linux-x64-20260530.tgz"    ;;
  Linux-arm64|Linux-aarch64) FILE="oss-cad-suite-linux-arm64-20260530.tgz" ;;
  *) echo "Unsupported platform: $OS-$ARCH"; exit 1 ;;
esac

URL="https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2026-05-30/$FILE"
DIR="$(cd "$(dirname "$0")" && pwd)/vendor"

mkdir -p "$DIR"

if [ -f "$DIR/oss-cad-suite/environment" ]; then
  echo "OSS CAD Suite already installed at $DIR/oss-cad-suite"
  exit 0
fi

echo "Downloading $FILE ..."
curl -L -o "$DIR/oss-cad-suite.tgz" "$URL"
echo "Extracting ..."
tar xf "$DIR/oss-cad-suite.tgz" -C "$DIR"
rm "$DIR/oss-cad-suite.tgz"
echo "Done."
