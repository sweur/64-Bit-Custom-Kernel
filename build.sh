#!/bin/bash
# Assembles the bootloader + kernel and builds a bootable disk image.
set -e

echo "[*] Assembling bootloader..."
nasm -f bin boot.asm -o boot.bin

echo "[*] Assembling kernel..."
nasm -f bin kernel.asm -o kernel.bin

echo "[*] Building disk image..."
cat boot.bin kernel.bin > disk.img
truncate -s 1474560 disk.img   # pad to floppy size (1.44MB)

echo "[*] Done. Run with: ./run.sh"
