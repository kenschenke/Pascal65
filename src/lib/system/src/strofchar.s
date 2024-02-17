; StringOfChar

.include "runtime.inc"

.export stringOfChar

.import loadParam, returnVal

ch = tmp1
count = tmp2

.proc stringOfChar
    lda #0
    jsr loadParam
    pha
    lda #1
    jsr loadParam
    pha
    clc
    adc #1
    ldx #0
    jsr rtHeapAlloc
    sta ptr1
    stx ptr1 + 1
    pla
    sta count
    pla
    sta ch
    ldy #0
    lda count
    tax
    sta (ptr1),y
    beq DN
    lda ch
:   iny
    sta (ptr1),y
    dex
    bne :-
DN: lda #0
    sta sreg
    sta sreg + 1
    lda ptr1
    ldx ptr1 + 1
    jmp returnVal
.endproc
