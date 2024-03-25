#!/bin/sh
set -e

if [ "$(id -u)" != "0" ]; then
	exec sudo sh "$0" "$@"
fi

# Hack to simulate ERR traps on non-Bash shells
rm -f .all_ok

PARTSIZE=10GiB
DEVICE=$1

usage() {
    echo "Usage: $0 [-p <partition size>] DEVICE"
    exit 1
}

if [ $# -ne 1 ]; then
    if [ $# -ne 3 ]; then
        usage
    fi
    if [ $1 != "-p" ]; then
        usage
    fi
    PARTSIZE=$2
    DEVICE=$3
fi

BASE=$(pwd)
NUM_DISTROS=$(echo $BASE/distros/* | wc --words)

exittrap() {
    if [ ! -e .all_ok ]; then
        set +e
        umount $BASE/mounts/*
        rm -rf $BASE/mounts
        losetup -D
    fi
    rm -f .all_ok
}

trap exittrap EXIT

# Hack: Make partition naming consistent by creating a loop device pointing to
#       the device we will be writing to.
DEVICE=$(losetup --partscan --find --show $DEVICE)
# Hack: for some reason partitions don't always show up immediately
sleep 1

(
    echo "label: gpt"
    echo "first-lba: 64"
    echo "table-length: $(( $NUM_DISTROS + 2 ))"
    echo "attrs=RequiredPartition, type=D7B1F817-AA75-2F4F-830D-84818A145370, start=64, size=32704, name=\"uboot_raw\""
    for distro in $BASE/distros/*; do
        . $distro/config
        echo "attrs=\"RequiredPartition,LegacyBIOSBootable\", size=$PARTSIZE, name=\"$PARTLABEL\""
    done
    echo "attrs=\"RequiredPartition,LegacyBIOSBootable\", size=+, name=\"ppp-multi-image-ut-data\""
) | sfdisk $DEVICE --wipe always

dd if=$BASE/downloads/ppp/foss/u-boot-rockchip.bin of=$DEVICE bs=512 seek=64
sync

mkfs.ext4 -F /dev/disk/by-partlabel/ppp-multi-image-ut-data

for distro in $BASE/distros/*; do
    sh $BASE/util/installdistro.sh $distro
done

losetup --detach $DEVICE
touch .all_ok
