.include "runtime.inc"

.export rtInitTensTable32

.data

tensTable32:
    .dword 1000000000
    .dword 100000000
    .dword 10000000
    .dword 1000000
    .dword 100000
    .dword 10000
    .dword 1000
    .dword 100
    .dword 10
    .dword 1

.code

; This routine is called by the generated code during initialization.
; A pointer to a 40-byte BSS block is passed in A/X. The routine sets
; the zero page pointer and then copies tensTable32 into the memory block.
; The zero page pointer is used anywhere else in code that needs the table.
.proc rtInitTensTable32
    sta tensTable32Ptr
    stx tensTable32Ptr + 1
    ldx #0
    ldy #0
:   lda tensTable32,x
    sta (tensTable32Ptr),y
    iny
    inx
    cpx #40
    bne :-
    rts
.endproc
