#!/bin/sh
set -e

BASE=$(pwd)
mkdir -p downloads && cd downloads

if [ ! -d ppp ]; then
    rm -f ppp # in case a `ppp` file exists for some reason
    rm -f ppp.tar.gz

    wget https://xff.cz/kernels/bootloaders-2024.04/ppp.tar.gz
    tar -xzf ppp.tar.gz
fi
rm -f ppp.tar.gz

for distro in $BASE/distros/*; do
    unset FNAME

    . $distro/config
    if [ -z $FNAME ]; then
        FNAME=$(basename $URL)
    fi

    case $METHOD in
        img)
            if [ ! -e ${FNAME%.*} ]; then
                rm -f $FNAME
                wget $URL
                $EXTRACT $FNAME
            fi
            ;;

        rootfs)
            if [ ! -e $FNAME ]; then

                # Sailfish puts a tar inside a zip, because of course it does.
                if [ $(basename $distro) == "sailfish" ]; then
                    rm -f artifacts.zip
                    wget $URL -O artifacts.zip
                    rm -rf pinephonepro
                    unzip artifacts.zip
                    rm -f artifacts.zip

                    mv $(find pinephonepro -name '*.tar.bz2' | tail -n 1) sailfish.tar.bz2
                    rm -rf pinephonepro

                    continue
                fi

                wget $URL
            fi
            ;;

        *)
            echo "Error: unknown method: $METHOD"
            exit 1
            ;;
    esac
done

cd $BASE
