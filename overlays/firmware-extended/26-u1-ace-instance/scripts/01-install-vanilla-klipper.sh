#!/usr/bin/env bash

KLIPPER_GIT_URL=https://github.com/Klipper3d/klipper.git
KLIPPER_GIT_SHA=9e8c4770eda8d09c865ed7fc7296df57a713597c
ACEPRO_GIT_URL=https://github.com/justinh-rahb/ACEPRO.git
ACEPRO_GIT_SHA=55ec2f75231fb7a2f8e4ddf2f7c3b68cfad9ff07

if [[ -z "$CREATE_FIRMWARE" ]]; then
  echo "Error: This script should be run within the create_firmware.sh environment."
  exit 1
fi

set -eo pipefail

KLIPPER_DIR="$CACHE_DIR/klipper-vanilla"
ACEPRO_DIR="$CACHE_DIR/ACEPRO"
INSTALL_DIR="$ROOTFS_DIR/home/lava/klipper-vanilla"

cache_git.sh "$KLIPPER_DIR" "$KLIPPER_GIT_URL" "$KLIPPER_GIT_SHA"
cache_git.sh "$ACEPRO_DIR" "$ACEPRO_GIT_URL" "$ACEPRO_GIT_SHA"

rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cp -a "$KLIPPER_DIR/." "$INSTALL_DIR/"

install -d "$INSTALL_DIR/klippy/extras/ace"
cp -a "$ACEPRO_DIR/extras/ace/." "$INSTALL_DIR/klippy/extras/ace/"
install -m 644 \
  "$ACEPRO_DIR/extras/virtual_pins.py" \
  "$INSTALL_DIR/klippy/extras/virtual_pins.py"

find_python_module_path() {
  local root="$1"
  local rel="$2"

  find \
    "$root/usr/lib" \
    "$root/usr/local/lib" \
    \( -path "*/python*/site-packages/$rel" -o \
       -path "*/python*/dist-packages/$rel" \) \
    2>/dev/null | head -n 1
}

echo ">> Verifying Python dependencies in target rootfs..."
JINJA2_PATH="$(find_python_module_path "$ROOTFS_DIR" 'jinja2/__init__.py')"
SERIAL_PATH="$(find_python_module_path "$ROOTFS_DIR" 'serial/__init__.py')"

if [[ -z "$JINJA2_PATH" ]]; then
  echo "Error: jinja2 is missing from the target rootfs."
  exit 1
fi

if [[ -z "$SERIAL_PATH" ]]; then
  echo "Error: pyserial is missing from the target rootfs."
  echo "Add a build-time installation step before enabling the ACE overlay."
  exit 1
fi

echo "   jinja2:  $JINJA2_PATH"
echo "   pyserial: $SERIAL_PATH"

chown -R 1000:1000 "$INSTALL_DIR"
