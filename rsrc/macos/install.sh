#!/bin/sh
set -e
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ARCH=$(uname -m)

mkdir -p /usr/local/lib
if [ "$ARCH" = "arm64" ]; then
  cp "$SCRIPT_DIR/lib_arm64/sunvox.dylib" /usr/local/lib/libsunvox.dylib
else
  cp "$SCRIPT_DIR/lib_x86_64/sunvox.dylib" /usr/local/lib/libsunvox.dylib
fi

install_name_tool -id /usr/local/lib/libsunvox.dylib /usr/local/lib/libsunvox.dylib 2>/dev/null || true
codesign --force --sign - /usr/local/lib/libsunvox.dylib 2>/dev/null || true
ln -sf /usr/local/lib/libsunvox.dylib /usr/local/lib/sunvox.dylib
