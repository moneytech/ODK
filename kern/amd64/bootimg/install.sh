#!/bin/bash

if test ! -f hd.img; then
  unxz < hd.img.xz > hd.img
  chmod 0777 hd.img
fi

LOOP=`losetup -o 32256 -v -f hd.img`
if [ $? -ne 0 ]; then
    echo Failed to set up loop device.
    exit 1
fi

LOOP=`echo $LOOP | awk '{print $4}'`

if [ $LOOP = "already" ]; then
    echo Image already mounted.
    exit 1
fi

echo Loop device is $LOOP

mkdir -p mntpt
mount $LOOP mntpt

cp menu.lst mntpt/
cp ../bootstrap.elf mntpt/
cp ../kernel.elf mntpt/

umount mntpt
sleep 1
umount mntpt
losetup -d $LOOP || exit 1

if [ -f mntpt/menu.lst ]; then exit 1; fi
rm -r mntpt
