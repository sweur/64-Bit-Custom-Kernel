#!/bin/bash
set -e

echo "[*] Assembling boot.asm (Multiboot2 header + entry point)..."
nasm -f elf32 boot.asm -o boot.o

echo "[*] Assembling kernel.asm..."
nasm -f elf32 kernel.asm -o kernel.o

echo "[*] Linking into mykernel.bin..."
if command -v i686-elf-ld >/dev/null 2>&1; then
    LD=i686-elf-ld
else
    LD="ld -m elf_i386"
fi
$LD -n -T linker.ld -o mykernel.bin boot.o kernel.o

echo "[*] Checking it's a valid Multiboot2 kernel..."
if command -v i686-elf-grub-file >/dev/null 2>&1; then
    GRUB_FILE=i686-elf-grub-file
    GRUB_MKRESCUE=i686-elf-grub-mkrescue
else
    GRUB_FILE=grub-file
    GRUB_MKRESCUE=grub-mkrescue
fi
$GRUB_FILE --is-x86-multiboot2 mykernel.bin && echo "    valid."

echo "[*] Building ISO with GRUB..."
mkdir -p isodir/boot/grub
cp mykernel.bin isodir/boot/mykernel.bin
cp grub.cfg isodir/boot/grub/grub.cfg
$GRUB_MKRESCUE -o mykernel.iso isodir

echo "[*] Done. Run with: ./run.sh"
