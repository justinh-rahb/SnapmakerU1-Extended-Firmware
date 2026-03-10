#!/usr/bin/env bash

ACEPRO_GIT_URL=https://github.com/justinh-rahb/ACEPRO.git
ACEPRO_GIT_SHA=55ec2f783410aadacb0776cf9649cad7694455cf

if [[ -z "$CREATE_FIRMWARE" ]]; then
  echo "Error: This script should be run within the create_firmware.sh environment."
  exit 1
fi

set -eo pipefail

ACEPRO_DIR="$CACHE_DIR/ACEPRO"
BASE_KLIPPER_DIR="$ROOTFS_DIR/home/lava/klipper"
ACE_KLIPPER_DIR="$ROOTFS_DIR/home/lava/klipper-ace"
ACE_EXTRAS_DIR="$ACE_KLIPPER_DIR/klippy/extras"
ACE_MCU_FILE="$ACE_KLIPPER_DIR/klippy/mcu.py"
SCRIPT_DIR="$(realpath "$(dirname "$0")")"
ACE_MCU_PATCH="$SCRIPT_DIR/../patches-runtime/01-ace-dummy-host-mcu.patch"

cache_git.sh "$ACEPRO_DIR" "$ACEPRO_GIT_URL" "$ACEPRO_GIT_SHA"

find_python_module_path() {
  local root="$1"
  local module="$2"

  find "$root" \
    \( -path "*/python*/$module/__init__.py" -o \
       -path "*/python*/$module/__init__.pyc" -o \
       -path "*/python*/site-packages/$module/__init__.py" -o \
       -path "*/python*/site-packages/$module/__init__.pyc" -o \
       -path "*/python*/dist-packages/$module/__init__.py" -o \
       -path "*/python*/dist-packages/$module/__init__.pyc" \) \
    2>/dev/null | head -n 1
}

echo ">> Verifying Python dependencies in target rootfs..."
JINJA2_PATH="$(find_python_module_path "$ROOTFS_DIR" 'jinja2')"
SERIAL_PATH="$(find_python_module_path "$ROOTFS_DIR" 'serial')"

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

if [[ ! -d "$BASE_KLIPPER_DIR" ]]; then
  echo "Error: missing stock Klipper tree at $BASE_KLIPPER_DIR"
  exit 1
fi

rm -rf "$ACE_KLIPPER_DIR"
mkdir -p "$ACE_KLIPPER_DIR"
cp -a "$BASE_KLIPPER_DIR/." "$ACE_KLIPPER_DIR/"

rm -rf "$ACE_EXTRAS_DIR/ace"
install -d "$ACE_EXTRAS_DIR/ace"
cp -a "$ACEPRO_DIR/extras/ace/." "$ACE_EXTRAS_DIR/ace/"
install -m 644 \
  "$ACEPRO_DIR/extras/virtual_pins.py" \
  "$ACE_EXTRAS_DIR/virtual_pins.py"

if [[ ! -f "$ACE_MCU_FILE" ]]; then
  echo "Error: missing copied MCU runtime at $ACE_MCU_FILE"
  exit 1
fi

if [[ ! -f "$ACE_MCU_PATCH" ]]; then
  echo "Error: missing ACE dummy MCU patch at $ACE_MCU_PATCH"
  exit 1
fi

patch -F 0 --no-backup-if-mismatch -d "$ACE_KLIPPER_DIR/klippy" -p0 < "$ACE_MCU_PATCH"

chown -R 1000:1000 "$ACE_KLIPPER_DIR"
