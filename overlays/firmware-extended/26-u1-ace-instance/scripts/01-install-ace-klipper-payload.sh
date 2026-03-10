#!/usr/bin/env bash

ACEPRO_GIT_URL=https://github.com/justinh-rahb/ACEPRO.git
ACEPRO_GIT_SHA=55ec2f783410aadacb0776cf9649cad7694455cf

if [[ -z "$CREATE_FIRMWARE" ]]; then
  echo "Error: This script should be run within the create_firmware.sh environment."
  exit 1
fi

set -eo pipefail

ACEPRO_DIR="$CACHE_DIR/ACEPRO"
PAYLOAD_DIR="$ROOTFS_DIR/usr/local/share/ace-klipper"

cache_git.sh "$ACEPRO_DIR" "$ACEPRO_GIT_URL" "$ACEPRO_GIT_SHA"

rm -rf "$PAYLOAD_DIR"
install -d "$PAYLOAD_DIR/ace"
cp -a "$ACEPRO_DIR/extras/ace/." "$PAYLOAD_DIR/ace/"
install -m 644 \
  "$ACEPRO_DIR/extras/virtual_pins.py" \
  "$PAYLOAD_DIR/virtual_pins.py"

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

chown -R 1000:1000 "$PAYLOAD_DIR"
