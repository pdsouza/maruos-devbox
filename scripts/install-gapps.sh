#!/bin/bash
#
# Copyright 2017 The Maru OS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# Automate Gapps installation for Maru OS.
#

set -e
set -u
# set -x

readonly DEPS="curl
adb
fastboot"

readonly GAPPS_PERMS_SCRIPT="fix-open-gapps-permissions.sh"

help () {
    cat <<EOF
Install gapps for Maru OS.

External dependencies (TWRP, gapps, etc.) are all cached under a device folder
in the working directory. Please ensure USB Debugging is enabled on your device
first!

Supported devices:
- hammerhead
- bullhead

Usage: $(basename "$0") [OPTIONS]

Options:

    -d, --device        Codename of device. Required.
EOF
}

readonly COL_RED="$(tput setaf 1)"
readonly COL_GREEN="$(tput setaf 2)"
readonly COL_DEF="$(tput op)"
iecho () { echo "[${COL_GREEN}*${COL_DEF}]" "$@"; }
fecho () { echo 1>&2 "[${COL_RED}x${COL_DEF}]" "$@"; }

check_deps () {
    for dep in $DEPS ; do
        if ! hash "$dep" 2>/dev/null ; then
            fecho "Missing dependency: ${dep}. Please install and re-run me."
            exit 2
        fi
    done
}

device_to_twrp_url () {
    local device="$1"
    case "$device" in
        hammerhead) echo "https://dl.twrp.me/hammerhead/twrp-3.0.3-0-hammerhead.img" ;;
        bullhead)   echo "https://dl.twrp.me/bullhead/twrp-3.0.2-2-bullhead.img" ;;
        *) echo ""
    esac
}

device_to_gapps_url () {
    local device="$1"
    case "$device" in
        hammerhead) echo "https://github.com/opengapps/arm/releases/download/20170112/open_gapps-arm-6.0-pico-20170112.zip" ;;
        bullhead)   echo "https://github.com/opengapps/arm64/releases/download/20170112/open_gapps-arm64-6.0-pico-20170112.zip" ;;
        *) echo ""
    esac
}

device_needs_gapps_perms_fix () {
    local device="$1"
    case "$device" in
        hammerhead) return -1 ;;
        bullhead) return 0 ;;
        *) return -1 ;;
    esac
}

dl () {
    local url="$1"
    curl -L -O "$url" || { fecho "Failed to download ${url}."; exit 1; }
}

dl_twrp () {
    local url="$1"
    curl -e "$url" -O "$url" || { fecho "Failed to download ${url}."; exit 1; }
}

OPT_DEVICE=
ARGS="$(getopt -o d: --long device:,help -n "$(basename "$0")" -- "$@")"
if [ $? != 0 ] ; then
    fecho "Error parsing options!"
    help
    exit 2
fi
eval set -- "$ARGS"

while true; do
    case "$1" in
        -d|--device) OPT_DEVICE="$2"; shift 2 ;;
        --help) help; exit 0 ;;
        --) shift; break ;;
    esac
done

if [ -z "$OPT_DEVICE" ] ; then
    fecho "You must specify a device!"
    echo
    help
    exit 2
fi

if [ -z "$(device_to_twrp_url "$OPT_DEVICE")" ] ; then
    fecho "$OPT_DEVICE is an unsupported device! See help below for supported devices."
    echo
    help
    exit 2
fi

iecho "Checking dependencies..."
check_deps

[ -d "$OPT_DEVICE" ] || mkdir "$OPT_DEVICE"

cd "$OPT_DEVICE"

if [ ! -e twrp* ] ; then
    iecho "Downloading TWRP..."
    dl_twrp "$(device_to_twrp_url $OPT_DEVICE)"
fi

if [ ! -e open_gapps* ] ; then
    iecho "Downloading gapps..."
    dl "$(device_to_gapps_url $OPT_DEVICE)"
fi

iecho "Rebooting into bootloader..."
adb reboot bootloader &>/dev/null || {
    fecho "adb failed to reboot into bootloader."
    exit 1
}
sleep 5

iecho "Flashing TWRP..."
fastboot flash recovery twrp*.img &>/dev/null || {
    fecho "fastboot failed to flash TWRP recovery."
    exit 1
}

iecho "Rebooting into system..."
fastboot reboot &>/dev/null || {
    fecho "fastboot failed to reboot into system."
    exit 1
}
sleep 25

iecho "Rebooting into recovery..."
adb reboot recovery &>/dev/null || {
    fecho "adb failed to reboot into recovery."
    exit 1
}
sleep 25

iecho "Installing gapps..."
gapps_file=(open_gapps*) # expand glob in list
adb push -p "$gapps_file" /sdcard/ || {
    fecho "adb failed to push gapps to /sdcard/."
    exit 1
}
adb shell twrp install "/sdcard/${gapps_file}" || {
    fecho "TWRP failed to install gapps."
    exit 1
}

iecho "Rebooting into system..."
adb reboot &>/dev/null || {
    fecho "adb failed to reboot into system."
    exit 1
}

if device_needs_gapps_perms_fix "$OPT_DEVICE" ; then
    sleep 55 # wait till framework boots
    iecho "Fixing up gapps permissions..."

    # search in both working dir and script dir for perms script
    script="$GAPPS_PERMS_SCRIPT"
    [ -f "$script" ] || script="$(dirname "$0")/${GAPPS_PERMS_SCRIPT}"
    [ -f "$script" ] || { fecho "Failed to find ${GAPPS_PERMS_SCRIPT}!"; exit 1; }

    adb push -p "$script" /sdcard/ &>/dev/null || {
        fecho "adb failed to push gapps permissions script to /sdcard/."
        exit 1
    }
    adb shell sh "/sdcard/${GAPPS_PERMS_SCRIPT}" || {
        fecho "Failed to run gapps permissions script."
        exit 1
    }
fi

iecho "All tasks completed successfully."
exit 0
