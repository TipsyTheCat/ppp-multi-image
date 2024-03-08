#!/bin/sh
set -e

BASE=$(pwd)
mkdir -p downloads && cd downloads

if [ ! -d ppp ]; then
    rm -f ppp # in case a `ppp` file exist for some reason
    rm -f ppp.tar.gz

    wget https://xff.cz/kernels/bootloaders-2024.04/ppp.tar.gz
    tar -xzf ppp.tar.gz
fi
rm -f ppp.tar.gz

for distro in $BASE/distros/*; do
    . $distro/config
    FNAME=$(basename $URL)

    if [ ! -e ${FNAME%.*} ]; then
        rm -f $FNAME
        wget $URL
        $EXTRACT $FNAME
    fi
done

cd $BASE
