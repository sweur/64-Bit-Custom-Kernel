#!/bin/bash
# Boots the OS in QEMU. Serial output is also logged to serial.log
# so the kernel's output is visible even without a display.
set -e
qemu-system-x86_64 -drive format=raw,file=disk.img -serial file:serial.log
