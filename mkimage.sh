#!/bin/sh
set -e

if [ "$(id -u)" != "0" ]; then
	exec sudo sh "$0" "$@"
fi

PARTSIZE=10G
DEVICE=$1

if [ $# -ne 1 ]; then
    if [ $# -ne 3 ]; then
        echo "Usage: $0 [-p <partition size>] DEVICE"
        exit 1
    fi
    if [ $1 != "-p" ]; then
        echo "Usage: $0 [-p <partition size>] DEVICE"
        exit 1
    fi
    PARTSIZE=$2
    DEVICE=$3
fi

BASE=$(pwd)
NUM_DISTROS=$(echo $BASE/distros/* | wc --words)

(
    echo "label: gpt"
    echo "first-lba: 64"
    echo "table-length: $(( $NUM_DISTROS + 2 ))"
    echo "attrs=RequiredPartition, type=D7B1F817-AA75-2F4F-830D-84818A145370, start=64, size=32704, name=\"uboot_raw\""
    for distro in $BASE/distros/*; do
        source $distro/config
        echo "attrs=\"RequiredPartition,LegacyBIOSBootable\", size=$PARTSIZE, name=\"$PARTLABEL\""
    done
    echo "attrs=\"RequiredPartition,LegacyBIOSBootable\", size=+, name=\"extra\""
) | sfdisk $DEVICE --wipe always
