.include "float.inc"

.export _strToFloat

.ifdef RUNTIME
.include "runtime.inc"
.else
.import intOp1
.importzp ptr1, sreg
.endif

.import FPINP

.proc _strToFloat
    sta ptr1
    stx ptr1 + 1
    ldx #0
    ldy #0
L1:
    lda (ptr1),y
    sta FPBUF,x
    beq L2
    inx
    iny
    bne L1
L2:
    jsr FPINP
    lda FPBASE + FPMSW
    sta sreg
    lda FPBASE + FPACCE
    sta sreg + 1
    lda FPBASE + FPLSW
    ldx FPBASE + FPNSW
    rts
.endproc