; This file is part of Simplix.
; It is part of the bootloader that starts the system.

; Currently, this file:
; - Sets the GDT
; - Enters protected mode
; - Enables the A20 line

org 0x7c00
[bits 16]

; defining our gdt offsets
CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

jmp short start
nop

; bios boot partition
times 33 db 0

start:
    jmp 0:step2

step2:
    cli ; clear interrupts

    ;todo: add checking for wrong bootdrives

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

.load_protected:
    cli
    lgdt [gdt_desc]

    ; setting protection enable bit in cr0
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

    ; jump to our 32 bit code
    jmp CODE_SEG:load_kernel

%include "./kernel/boot/gdt.asm"

[bits 32]
load_kernel:
    mov eax, 1
    mov ecx, 100
    mov edi, 0x0100000

    call ata_lba_read

    jmp CODE_SEG:0x0100000
    ;jmp $

; Reads the hard disk in LBA mode.
ata_lba_read:

    ; save eax inside eax
    mov ebx, eax

    ; get the high 8 bits of lba
    ; by bitshifting right by 24, we move the top
    ; 8 bits of eax into al.
    shr eax, 24
    or eax, 0xe0

    ; port address to write to
    mov dx, 0x1f6
    out dx, al ; send high 8 bits to the lba

    ; send the total sectors to read
    mov eax, ecx
    mov dx, 0x1f2
    out dx, al

    ; sending more bits of the lba
    mov eax, ebx ; restore backed up lba
    mov dx, 0x1f3
    out dx, al

    mov dx, 0x1f4
    mov eax, ebx
    shr eax, 8
    out dx, al

    ; send upper 16 bits
    mov dx, 0x1f5
    mov eax, ebx
    shr eax, 16
    out dx, al

    mov dx, 0x1f7
    mov al, 0x20
    out dx, al

    ; read all sectors into memory
.next_sector:
    push ecx

.try_again:
    mov dx, 0x1f7
    in al, dx
    test al, 8
    jz .try_again

    ;reading 256 words (512 bytes)
.continue:
    mov ecx, 256
    mov dx, 0x1f0
    rep insw
    pop ecx
    loop .next_sector

; done reading sectors
.done:
    ret


times 510 - ($ - $$) db 0
dw 0xaa55
