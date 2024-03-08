#!/bin/sh
set -e

if [ "$(id -u)" != "0" ]; then
	exec sudo sh "$0" "$@"
fi

# Hack to simulate ERR traps on non-Bash shells
rm -f .all_ok

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

trap "if [ ! -e .all_ok ]; then set +e; umount $BASE/mounts/*; rm -rf $BASE/mounts; losetup -D; fi; rm -f .all_ok;" EXIT

# Hack: Make partition naming consistent by creating a loop device pointing to
#       the device we will be writing to.
DEVICE=$(losetup --partscan --find --show $DEVICE)

rm -rf mounts
mkdir -p mounts/src_root mounts/src_boot mounts/dst

(
    echo "label: gpt"
    echo "first-lba: 64"
    echo "table-length: $(( $NUM_DISTROS + 2 ))"
    echo "attrs=RequiredPartition, type=D7B1F817-AA75-2F4F-830D-84818A145370, start=64, size=32704, name=\"uboot_raw\""
    for distro in $BASE/distros/*; do
        . $distro/config
        echo "attrs=\"RequiredPartition,LegacyBIOSBootable\", size=$PARTSIZE, name=\"$PARTLABEL\""
    done
    echo "attrs=\"RequiredPartition,LegacyBIOSBootable\", size=+, name=\"extra\""
) | sfdisk $DEVICE --wipe always

dd if=$BASE/downloads/ppp/foss/u-boot-rockchip.bin of=$DEVICE bs=512 seek=64
sync

for distro in $BASE/distros/*; do
    . $distro/config
    SRC_IMAGE_ARCHIVE=$(basename $URL)
    SRC_IMG=${SRC_IMAGE_ARCHIVE%.*}

    SRC_LOOP=$(losetup --partscan --find --show $BASE/downloads/$SRC_IMG)
    mount ${SRC_LOOP}p${BOOT_PT} $BASE/mounts/src_boot
    mount ${SRC_LOOP}p${ROOT_PT} $BASE/mounts/src_root

    mkfs.ext4 -F /dev/disk/by-partlabel/$PARTLABEL
    mount /dev/disk/by-partlabel/$PARTLABEL $BASE/mounts/dst
    rsync --archive --numeric-ids $BASE/mounts/src_root/* $BASE/mounts/dst/
    rsync --archive --numeric-ids $BASE/mounts/src_boot/* $BASE/mounts/dst/boot/
    rm -f $BASE/mounts/dst/boot/*.scr
    cp -r $distro/overrides/* $BASE/mounts/dst/

    umount $BASE/mounts/dst
    umount $BASE/mounts/src_boot
    umount $BASE/mounts/src_root
    losetup --detach $SRC_LOOP
done

rm -rf mounts
losetup --detach $DEVICE
touch .all_ok
