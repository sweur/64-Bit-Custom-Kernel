; ============================================================
; boot.asm — Multiboot2 header + entry point.
; GRUB reads the header below to recognize this as a bootable
; kernel, loads it into memory, sets up 32-bit protected mode
; for us (no more hand-written BIOS disk/real-mode code!), and
; jumps straight to _start.
; ============================================================

section .multiboot
align 8
multiboot_header:
    dd 0xE85250D6                ; magic number GRUB looks for
    dd 0                          ; architecture: 0 = 32-bit (i386) protected mode
    dd header_end - multiboot_header   ; total header length
    dd -(0xE85250D6 + 0 + (header_end - multiboot_header))  ; checksum

    ; end tag — required, marks "no more tags"
    dw 0
    dw 0
    dd 8
header_end:

section .bss
align 16
stack_bottom:
    resb 16384                    ; 16KB stack
stack_top:

section .text
[bits 32]
global _start
extern kernel_main

_start:
    mov esp, stack_top            ; GRUB doesn't set up a stack for us — we do it

    call kernel_main               ; hand off to our actual kernel code

.hang:
    cli
    hlt
    jmp .hang
