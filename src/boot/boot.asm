org 0x7c00
[bits 16]

; defining our gdt offsets
CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

_start:
    jmp short start
    nop

; bios boot partition
times 33 db 0

start:
    jmp 0:start2

start2:
    cli ; clear interrupts

    ; load the segment into gpr ax
    mov ax, 0x00
    ; load the data and extra segment with ax (0x7c0)
    mov ds, ax
    mov es, ax

    ; set the stack segment to 0
    ;mov ax, 0x00
    ;mov ss, ax

    ; set the stack pointer to 7c00h
    mov sp, 0x7c00

    sti ; re-enable interrupts

    ; setting up for a read to the drive
    mov ah, 2 
    mov al, 1 ; number of sectors to read
    mov ch, 0 ; cylinder low eight bits
    mov cl, 2 ; read sector two
    mov dh, 0 ; head number
    mov bx, buffer

    ; ; call the bios drive read subroutine
    ; int 0x13

    ; ; if carry flag is set, we have an error
    ; ; jump to our error handler routine
    ; jc error

    ; ; move the buffer pointer into si
    ; mov si, buffer
    ; call print
    ; jmp $

.load_protected:
    cli
    lgdt [gdt_desc]

    ; enabling protection enable bit in cr0
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

    ; jump to our 32 bit code
    jmp CODE_SEG:load32

; ------ GDT ------
gdt_start:


gdt_null:        ; defining a GDT null entry 
    dd 0x0
    dd 0x0

; offset 0x8
gdt_code:        ; cs should point to this
    dw 0xffff    ; segment limit bits 0-15
    dw 0x0       ; segment base bits 0-15
    db 0         ; base bits 16-23
    db 10011010b ; access byte
    db 11001111b ;
    db 0         ; base segment bits 24-31

; offset 0x10
gdt_data:        ; ds, ss, es, fs, gs
    dw 0xffff    ; segment limit bits 0-15
    dw 0x0       ; segment base bits 0-15
    db 0         ; base bits 16-23
    db 10010010b ; access byte, data segment, so Ex bit unset
    db 11001111b ;
    db 0         ; base segment bits 24-31

gdt_end:

gdt_desc:        ; gdt pointer
    dw gdt_end-gdt_start-1
    dd gdt_start

[bits 32]
load32:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; setting up stack
    mov ebp, 0x00200000
    mov esp, ebp

    jmp $

times 510 - ($ - $$) db 0
dw 0xaa55

buffer: