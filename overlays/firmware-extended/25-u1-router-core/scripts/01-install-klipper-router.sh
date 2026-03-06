#!/usr/bin/env bash

GIT_URL=https://github.com/justinh-rahb/klipper-router.git
GIT_SHA=c350612121cb71e914ecbcff0523a46cfab07e36

if [[ -z "$CREATE_FIRMWARE" ]]; then
  echo "Error: This script should be run within the create_firmware.sh environment."
  exit 1
fi

set -eo pipefail

TARGET_DIR="$CACHE_DIR/klipper-router"
cache_git.sh "$TARGET_DIR" "$GIT_URL" "$GIT_SHA"

install -d "$ROOTFS_DIR/usr/local/sbin"
install -m 755 "$TARGET_DIR/src/klipper_router.py" "$ROOTFS_DIR/usr/local/sbin/klipper-routerd"

install -d "$ROOTFS_DIR/usr/local/share/firmware-config/router/includes"
install -m 644 \
  "$TARGET_DIR/includes/router_api.cfg" \
  "$ROOTFS_DIR/usr/local/share/firmware-config/router/includes/router_api.cfg"
