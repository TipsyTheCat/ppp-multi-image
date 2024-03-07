# PinePhone Pro multi-distribution SD card image

Ensure the following packages are installed:

* `wget`
* `rsync`

Execute the following commands from the root of the project directory:

```shell
./download.sh
./mkimage.sh [-p <partition size>] /dev/[DEVICE] # e.g. ./mkimage.sh -p 11G /dev/mmcblk0
```

See also: https://xff.cz/git/pinephone-multi-boot
