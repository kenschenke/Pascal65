.include "float.inc"

.ifdef RUNTIME
.include "runtime.inc"
.else
.importzp sreg
.endif

.import FPBASE, COMPLM

.export floatNeg

.proc floatNeg
    jsr storeFPACC
    ldx #FPLSW
    ldy #3
    jsr COMPLM
    jmp loadFPACC
.endproc

.proc loadFPACC
    lda FPBASE + FPMSW
    sta sreg
    lda FPBASE + FPACCE
    sta sreg + 1
    lda FPBASE + FPLSW
    ldx FPBASE + FPNSW
    rts
.endproc

.proc storeFPACC
    sta FPBASE + FPLSW
    stx FPBASE + FPNSW
    lda sreg
    sta FPBASE + FPMSW
    lda sreg + 1
    sta FPBASE + FPACCE
    lda #0
    sta FPBASE + FPLSWE
    rts
.endproc
