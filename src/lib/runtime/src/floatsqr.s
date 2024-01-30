.include "float.inc"

.ifdef RUNTIME
.include "runtime.inc"
.endif

.import MOVIND, FPMULT

.export floatSqr

.proc floatSqr
    lda #FPLSW
    sta FPBASE + FMPNT
    lda #FOPLSW
    sta FPBASE + TOPNT
    ldx #4
    jsr MOVIND
    jmp FPMULT
.endproc
