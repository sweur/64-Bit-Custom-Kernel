; ============================================================
; kernel.asm — the "kernel" itself
; The bootloader jumps here after switching to 64-bit long mode.
; This is a flat binary loaded at physical address 0x8000, so
; org must match where the bootloader put it.
;
; All this does right now: write text directly into the VGA
; text-mode buffer (a fixed memory address the screen reads from)
; and halt. That's the "hello world" of OS dev — proving you can
; control the machine at the lowest level, with no OS underneath you.
; ============================================================

jmp kernel_start
[org 0x8000]
[bits 64]
CODE64_SEG equ 8
lidt [idt_descriptor]

idt_keyboard_entry:           ; IDT Table
    dw 0
    dw CODE64_SEG                         ; selector which segment? (you defined this already)
    db 0
    db 10001110b                          ; type_attr
    dw 0
    dd 0
    dd 0

    mov rax, keyboard_handler
    mov [idt_keyboard_entry], ax
    shr rax, 16
    mov [idt_keyboard_entry+6], ax
    shr rax, 16
    mov [idt_keyboard_entry+8], eax

keyboard_handler:
    ; (later: we'll read the actual key here)

    mov al, 0x20
    out 0x20, al        ; tell the PIC "interrupt handled"

    iretq

idt_descriptor:
    dw 15    
    dd idt_keyboard_entry

kernel_start:
    mov rsi, message
.serial_loop:
    mov al, [rsi]
    cmp al, 0
    je .vga_output
    mov dx, 0x3F8
    out dx, al
    inc rsi
    jmp .serial_loop

.vga_output:
    mov rdi, 0xB8000
    mov ah, 0x0F
    mov al, ' '
    mov rcx, 80*25
.clear_loop:
    mov [rdi], al
    mov [rdi+1], ah
    add rdi, 2
    loop .clear_loop

    mov rdi, 0xB8000        ; VGA text buffer: each char = 2 bytes (ascii, color)
    mov rsi, message
    mov ah, 0x0F            ; color byte: white text on black background

.print_loop:
    mov al, [rsi]           ; load next character
    cmp al, 0
    je .halt
    mov [rdi], al            ; write the character byte
    mov [rdi+1], ah          ; write the color byte
    add rdi, 2
    inc rsi
    jmp .print_loop

.halt:
    cli
.hang:
    hlt                      ; halt CPU until next interrupt (we disabled them, so: forever)
    jmp .hang

message: db "Hello from my own 64-bit kernel!", 0
