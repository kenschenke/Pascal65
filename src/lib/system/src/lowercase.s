; LowerCase

.include "runtime.inc"

.export lowerCase

.import loadParam, returnVal, isAlpha

len = tmp1

.proc lowerCase
    lda #0
    jsr loadParam
    sta ptr1
    pha
    stx ptr1 + 1
    txa
    pha
    ldy #0
    lda (ptr1),y
    pha
    clc
    adc #1
    ldx #0
    jsr rtHeapAlloc
    sta ptr2
    stx ptr2 + 1
    pla
    sta len
    pla
    sta ptr1 + 1
    pla
    sta ptr1
    ldy #0
    lda len
    sta (ptr2),y
    beq DN
LP: iny
    lda (ptr1),y
    jsr isAlpha
    cpx #0
    beq :+
    and #$7f
:   sta (ptr2),y
    dec len
    bne LP
DN: lda #0
    sta sreg
    sta sreg + 1
    lda ptr2
    ldx ptr2 + 1
    jmp returnVal
.endproc
