# PinePhone Pro multi-distribution SD card image

Ensure the following packages are installed:

* `wget`
* `rsync`
* `unzip`

Execute the following commands from the root of the project directory:

```shell
./download.sh
./mkimage.sh [-p <partition size>] /dev/[DEVICE] # e.g. ./mkimage.sh -p 11G /dev/mmcblk0
```

See also:

* [Megi's multi-distro image script for the PinePhone (non-Pro)](https://xff.cz/git/pinephone-multi-boot)
* [Manual installation guide](https://pine64.org/documentation/PinePhone_Pro/Software/Multi-distribution_image/)
