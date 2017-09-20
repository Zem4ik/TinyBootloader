# TinyBootloader

## Description

This is tiny bootlader which allows you to boot from any active primary partition (extended partition is not supported). It copies VBR from begginnging of chosen partition and passes control to it.

## How to install

First of all, you need to download [boot.bin]. Other steps depend on system you are working with.

### Windows

You will need BootIce (run and install it). Then do the following steps:
* Run it as an administrator
* "Process MBR"
* "Restore MBR"
* Choose downloaded 'boot.bin' and click "Restore" (but select "Keep signature and partition table untouched")

Ready!

### Linux

Run `sudo dd if=<working dir>/boot.bin of=/dev/sdb bs=446 count=1` ('sdb' can be replaced by other device).
