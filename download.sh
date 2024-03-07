#!/bin/sh
set -e

BASE=$(pwd)
rm -rf downloads
mkdir downloads
cd downloads

wget https://xff.cz/kernels/bootloaders-2024.04/ppp.tar.gz
tar -xzf ppp.tar.gz

for distro in $BASE/distros/*; do
    . $distro/config
    wget $URL
    $EXTRACT $(basename $URL)
done

cd $BASE
