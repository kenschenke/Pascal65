.include "float.inc"
.include "runtime.inc"

.export floatSqr

.import MOVIND, FPMULT
.proc floatSqr
    lda #FPLSW
    sta FPBASE + FMPNT
    lda #FOPLSW
    sta FPBASE + TOPNT
    ldx #4
    jsr MOVIND
    jmp FPMULT
.endproc
