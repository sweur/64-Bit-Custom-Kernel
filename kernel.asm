
[org 0x8000]
[bits 64]
jmp kernel_start
CODE64_SEG equ 8


idt_start:
    times 256*16 db 0
idt_end:

keyboard_handler:
    ; (later: we'll read the actual key here)

    mov al, 0x20
    out 0x20, al        ; tell the PIC "interrupt handled"

    iretq

idt_descriptor:
    dw idt_end - idt_start - 1
    dd idt_start

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
idt_start:
    times 256*16 db 0
idt_end:

idt_descriptor:
    dw idt_end - idt_start - 1
    dd idt_start

keyboard_handler:
    mov al, 0x20
    out 0x20, al
    iretq

mouse_handler:
    in al, 0x60           ; read (and discard) the mouse's data byte for now
    mov al, 'M'
    mov dx, 0x3F8
    out dx, al             ; proof-of-life: log 'M' to serial every time this fires
    mov al, 0x20
    out 0xA0, al           ; tell PIC2 "handled" (mouse lives on PIC2)
    out 0x20, al           ; ALSO tell PIC1 required any time a PIC2 IRQ fires
    iretq

enable_mouse:
    mov al, 0xA8
    out 0x64, al           ; tell the 8042 controller: turn on the mouse port

    mov al, 0x20
    out 0x64, al           ; command: "give me your config byte"
    in al, 0x60
    or al, 2                ; flip on "allow mouse interrupts"
    mov bl, al
    mov al, 0x60
    out 0x64, al           ; command: "here's your new config byte"
    mov al, bl
    out 0x60, al

    mov al, 0xD4            ; 0xD4 means "this next byte is FOR the mouse"
    out 0x64, al
    mov al, 0xF4            ; mouse command: "start sending movement data"
    out 0x60, al
    ret

kernel_start:
    mov rax, keyboard_handler
    mov [idt_start + 0x21*16], ax
    mov word [idt_start + 0x21*16 + 2], CODE64_SEG
    mov byte [idt_start + 0x21*16 + 4], 0
    mov byte [idt_start + 0x21*16 + 5], 10001110b
    shr rax, 16
    mov [idt_start + 0x21*16 + 6], ax
    shr rax, 16
    mov [idt_start + 0x21*16 + 8], eax

    mov rax, mouse_handler
    mov [idt_start + 0x2C*16], ax
    mov word [idt_start + 0x2C*16 + 2], CODE64_SEG
    mov byte [idt_start + 0x2C*16 + 4], 0
    mov byte [idt_start + 0x2C*16 + 5], 10001110b
    shr rax, 16
    mov [idt_start + 0x2C*16 + 6], ax
    shr rax, 16
    mov [idt_start + 0x2C*16 + 8], eax

    lidt [idt_descriptor]

    mov al, 0x11
    out 0x20, al
    out 0xA0, al
    mov al, 0x20
    out 0x21, al
    mov al, 0x28
    out 0xA1, al
    mov al, 0x04
    out 0x21, al
    mov al, 0x02
    out 0xA1, al
    mov al, 0x01
    out 0x21, al
    out 0xA1, al
    mov al, 11111001b   ; PIC1: unmask keyboard(1) + cascade(2), mask rest
    out 0x21, al
    mov al, 11101111b   ; PIC2: unmask mouse(bit4), mask rest
    out 0xA1, al

    call enable_mouse
    sti                    ; interrupts are OFF by default this turns them on

.halt:

.hang:
    hlt                      ; halt CPU until next interrupt (we disabled them, so: forever)
    jmp .hang

message: db "Hello from my own 64-bit kernel!", 0
