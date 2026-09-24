# x64-kernel

A tiny x86-64 kernel written in NASM assembly. No C, no bootloader framework just raw asm handling every step from power-on to a running 64-bit kernel.

I built this to actually understand what happens between pressing the power button and an OS running and to learn ASM, instead of just knowing the terms.

## How it boots

- BIOS loads the boot sector (`boot.asm`) at `0x7C00` that address is fixed by the hardware, not a choice.
- Real mode (16-bit): loads the kernel off disk using BIOS disk interrupts, since there's no disk driver yet.
- Enables the A20 line (an old IBM PC compatibility thing that has to be switched off manually before you can address more than 1MB).
- Protected mode (32-bit): sets up a GDT and flips the PE bit in CR0.
- Builds page tables by hand (PML4 → PDPT → PD) to identity-map the first 2MB. Long mode won't work without paging on.
- Long mode (64-bit): enables PAE, sets the LME bit in the EFER MSR, turns on paging, jumps into 64-bit code.
- Kernel (`kernel.asm`): writes to the VGA text buffer and the serial port, sets up an IDT so keyboard interrupts have somewhere to go.

## Running it

Needs `nasm` and `qemu-system-x86_64`.

```bash
./build.sh
./run.sh
```

Prints to the QEMU window and logs to `serial.log`.

## Files

```
boot.asm    — real mode -> protected mode -> long mode
kernel.asm  — 64-bit kernel, loaded at 0x8000
build.sh    — assembles everything into a bootable image
run.sh      — boots it in QEMU
```

## Status

- [x] Boots into 64-bit long mode (TEMPORARILY IN 32-bit PROTECTED MODE)
- [x] Displays GRUB/Multiboot 2 bootloader menu
- [x] Writes to screen and serial
- [x] IDT set up with a keyboard handler entry
- [ ] PIC remapped so keyboard interrupts actually fire
- [ ] Reading real keypresses
- [ ] Basic shell
- [ ] Command line environment
- [ ] Filesystem (Either will be written to RAM 0 persistence or actual stored memory, will update when decided)
- [ ] Basic commands (help, cd, ls, whoami, cat, rm, nano)
- [ ] Custom fastfetch
- [ ] Some sort of CLI game built in
