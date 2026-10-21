#!/bin/sh
set -e
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ARCH=$(uname -m)

case "$ARCH" in
  aarch64|arm64)
    LIB_SRC="$SCRIPT_DIR/lib_arm64/sunvox.so"
    ;;
  armv7*|arm*)
    LIB_SRC="$SCRIPT_DIR/lib_arm/sunvox.so"
    ;;
  i386|i686)
    LIB_SRC="$SCRIPT_DIR/lib_x86/sunvox.so"
    ;;
  *)
    LIB_SRC="$SCRIPT_DIR/lib_x86_64/sunvox.so"
    ;;
esac

cp "$LIB_SRC" /usr/lib/libsunvox.so
ln -sf /usr/lib/libsunvox.so /usr/lib/sunvox.so
ln -sf /usr/lib/libsunvox.so /lib/sunvox.so 2>/dev/null || true
if [ -d /usr/lib/x86_64-linux-gnu ]; then
  ln -sf /usr/lib/libsunvox.so /usr/lib/x86_64-linux-gnu/libsunvox.so
  ln -sf /usr/lib/libsunvox.so /usr/lib/x86_64-linux-gnu/sunvox.so
fi
ldconfig 2>/dev/null || true
