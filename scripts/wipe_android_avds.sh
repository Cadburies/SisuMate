#!/usr/bin/env bash
# Wipe Android emulator user data (apps, local DBs) without deleting the AVDs.
# Safe offline: removes userdata overlays + snapshots so next boot is factory-clean.
set -euo pipefail

AVD_ROOT="${ANDROID_AVD_HOME:-$HOME/.android/avd}"

if [[ ! -d "$AVD_ROOT" ]]; then
  echo "No AVD root at $AVD_ROOT"
  exit 1
fi

wipe_one() {
  local dir="$1"
  local name
  name="$(basename "$dir" .avd)"
  echo "Wiping AVD data: $name ($dir)"
  rm -rf "${dir}/snapshots"
  rm -rf "${dir}/data"
  rm -rf "${dir}/tmpAdbCmds"
  rm -f "${dir}/userdata-qemu.img"
  rm -f "${dir}/userdata-qemu.img.qcow2"
  rm -f "${dir}/cache.img.qcow2"
  rm -f "${dir}/encryptionkey.img.qcow2"
  rm -f "${dir}/sdcard.img.qcow2"
  rm -f "${dir}/multiinstance.lock"
  rm -f "${dir}/bootcompleted.ini"
  rm -f "${dir}/hardware-qemu.ini"
  rm -f "${dir}/read-snapshot.txt"
  rm -f "${dir}/snapshot.trace"
  rm -f "${dir}/emu-launch-params.txt"
  # If a clean userdata template exists, reseed the base image for next boot.
  if [[ -f "${dir}/userdata.img" ]]; then
    cp "${dir}/userdata.img" "${dir}/userdata-qemu.img"
  fi
  echo "  done: $name"
}

count=0
for d in "$AVD_ROOT"/*.avd; do
  if [[ -d "$d" ]]; then
    wipe_one "$d"
    count=$((count + 1))
  fi
done

if [[ "$count" -eq 0 ]]; then
  echo "No *.avd directories under $AVD_ROOT"
  exit 1
fi

echo "Wiped $count Android AVD(s)."
