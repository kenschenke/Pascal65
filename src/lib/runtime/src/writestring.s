.include "cbm_kernal.inc"
.include "runtime.inc"

.export writeString

.import leftpad

; Pointer to string heap in A/X
; Field width in Y
.proc writeString
    sta ptr1
    stx ptr1 + 1
    cpy #0
    beq SK
    tya
    pha
    ldy #0
    lda (ptr1),y
    tax
    pla
    jsr leftpad
SK: ldy #0
    lda (ptr1),y
    tax
    beq DN
LP: iny
    lda (ptr1),y
    jsr CHROUT
    dex
    bne LP
DN: rts
.endproc

