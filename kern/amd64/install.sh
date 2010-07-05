#!/bin/bash

xz < hd.img.xz > hd.img

LOOP=`losetup -o 32256 -v -f hd.img`
if [ $? -ne 0 ]; then
    echo Failed to set up loop device.
    exit 1
fi

LOOP=`echo $LOOP | awk '{print $4}'`
echo Loop device is $LOOP

mkdir -p mntpt
mount $LOOP mntpt

cp kernel.elf mntpt/

umount mntpt
losetup -d $LOOP

rm -r mntpt
