[bits 16]

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