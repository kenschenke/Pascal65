.include "cbm_kernal.inc"

.export printz, printlnz
.importzp ptr1

.proc printz
    sta ptr1
    stx ptr1 + 1

    ; loop until 0 byte
    ldy #0
L1:
    lda (ptr1),y
    beq L2
    jsr CHROUT
    iny
    jmp L1

L2:
    rts
.endproc

.proc printlnz
    jsr printz
    lda #13
    jsr CHROUT
    rts
.endproc
