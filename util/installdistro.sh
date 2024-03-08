#!/bin/sh
set -e

if [ "$(id -u)" != "0" ]; then
	exec sudo sh "$0" "$@"
fi

BASE=$(pwd)

usage() {
    echo "Usage: $0 distros/<distro> [DEVICE]"
    exit 1
}

unset DEVICE
if [ $# -ne 1 ]; then
    if [ $# -ne 2 ]; then
        usage
    else
        DEVICE=$(losetup --partscan --find --show $2)
        # Hack: for some reason partitions don't always show up immediately
        sleep 1
    fi
fi
distro="$1"

unset FNAME

. $distro/config
if [ -z $FNAME ]; then
    SRC_IMAGE_ARCHIVE=$(basename $URL)
else
    SRC_IMAGE_ARCHIVE="$FNAME"
fi

rm -rf mounts
mkdir -p mounts/src_root mounts/src_boot mounts/dst

mkfs.ext4 -F /dev/disk/by-partlabel/$PARTLABEL
mount /dev/disk/by-partlabel/$PARTLABEL $BASE/mounts/dst

cleanup() {
    true
}
case $METHOD in
    img)
        SRC_IMG=${SRC_IMAGE_ARCHIVE%.*}
        SRC_LOOP=$(losetup --partscan --find --show $BASE/downloads/$SRC_IMG)
        mount ${SRC_LOOP}p${BOOT_PT} $BASE/mounts/src_boot
        mount ${SRC_LOOP}p${ROOT_PT} $BASE/mounts/src_root

        rsync --archive --numeric-ids $BASE/mounts/src_root/* $BASE/mounts/dst/
        rsync --archive --numeric-ids $BASE/mounts/src_boot/* $BASE/mounts/dst/boot/

        cleanup() {
            umount $BASE/mounts/src_boot
            umount $BASE/mounts/src_root
            losetup --detach $SRC_LOOP
        }
        ;;

    rootfs)
        $TAR_CMD $BASE/downloads/$SRC_IMAGE_ARCHIVE --numeric-owner \
                 --directory=$BASE/mounts/dst
        ;;

    *)
        echo "Error: unknown method: $METHOD"
        exit 1
        ;;
esac

rm -f $BASE/mounts/dst/boot/*.scr $BASE/mounts/dst/boot/*.cmd
cp -r $distro/overrides/* $BASE/mounts/dst/

umount $BASE/mounts/dst
cleanup
rm -rf mounts

if [ ! -z $DEVICE ]; then
    losetup --detach $DEVICE
fi
