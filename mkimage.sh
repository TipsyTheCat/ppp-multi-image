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

# Hack: Make partition naming consistent by creating a loop device pointing to
#       the device we will be writing to.
DEVICE=$(losetup --partscan --find --show $DEVICE)

rm -rf mounts
mkdir -p mounts/{src_root,src_boot,dst}

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

dd if=$BASE/downloads/ppp/foss/u-boot-rockchip.bin of=$DEVICE bs=512 seek=64
sync

for distro in $BASE/distros/*; do
    source $distro/config
    SRC_IMAGE_ARCHIVE=$(basename $URL)
    SRC_IMG=${SRC_IMAGE_ARCHIVE%.*}

    SRC_LOOP=$(losetup --partscan --find --show $BASE/downloads/$SRC_IMG)
    mount ${SRC_LOOP}p${BOOT_PT} $BASE/mounts/src_boot
    mount ${SRC_LOOP}p${ROOT_PT} $BASE/mounts/src_root

    mkfs.ext4 /dev/disk/by-partlabel/$PARTLABEL
    mount /dev/disk/by-partlabel/$PARTLABEL $BASE/mounts/dst
    rsync -a $BASE/mounts/src_root/* $BASE/mounts/dst/
    rsync -a $BASE/mounts/src_boot/* $BASE/mounts/dst/

    umount $BASE/mounts/dst
    umount $BASE/mounts/src_boot
    umount $BASE/mounts/src_root
    losetup --detach $SRC_LOOP
done

rm -rf mounts
losetup --detach $DEVICE
