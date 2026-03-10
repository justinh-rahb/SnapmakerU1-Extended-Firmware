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

python3 - "$ACE_MCU_FILE" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text()

old = """            self._serialport = config.get('serial')\n            if not (self._serialport.startswith(\"/dev/rpmsg_\")\n                    or self._serialport.startswith(\"/tmp/klipper_host_\")):\n                self._baud = config.getint('baud', 250000, minval=2400)\n"""
new = """            self._serialport = config.get('serial')\n            self._ace_u1_dummy_mcu = self._serialport == \"/tmp/klipper_host_mcu\"\n            if not (self._serialport.startswith(\"/dev/rpmsg_\")\n                    or self._serialport.startswith(\"/tmp/klipper_host_\")):\n                self._baud = config.getint('baud', 250000, minval=2400)\n"""
if old not in text:
    raise SystemExit("unable to locate serial port initialization in copied mcu.py")
text = text.replace(old, new, 1)

old = """    def _handle_shutdown(self, params):\n        if self._is_shutdown:\n            return\n"""
new = """    def _handle_shutdown(self, params):\n        if self._ace_u1_dummy_mcu:\n            logging.info(\"ACE dummy MCU ignoring shutdown event on shared host endpoint\")\n            return\n        if self._is_shutdown:\n            return\n"""
if old not in text:
    raise SystemExit("unable to locate shutdown handler in copied mcu.py")
text = text.replace(old, new, 1)

old = """    def _handle_starting(self, params):\n        if not self._is_shutdown:\n            self._printer.invoke_async_shutdown(\"MCU '%s' spontaneous restart\"\n                                                % (self._name,))\n"""
new = """    def _handle_starting(self, params):\n        if self._ace_u1_dummy_mcu:\n            logging.info(\"ACE dummy MCU ignoring spontaneous restart on shared host endpoint\")\n            return\n        if not self._is_shutdown:\n            self._printer.invoke_async_shutdown(\"MCU '%s' spontaneous restart\"\n                                                % (self._name,))\n"""
if old not in text:
    raise SystemExit("unable to locate starting handler in copied mcu.py")
text = text.replace(old, new, 1)

old = """    def check_timeout(self, eventtime):\n        if (self._clocksync.is_active() or self._mcu.is_fileoutput()\n            or self._is_timeout):\n            return\n"""
new = """    def check_timeout(self, eventtime):\n        if self._ace_u1_dummy_mcu:\n            return\n        if (self._clocksync.is_active() or self._mcu.is_fileoutput()\n            or self._is_timeout):\n            return\n"""
if old not in text:
    raise SystemExit("unable to locate timeout handler in copied mcu.py")
text = text.replace(old, new, 1)

path.write_text(text)
PY

chown -R 1000:1000 "$ACE_KLIPPER_DIR"
