.include "float.inc"

.ifdef RUNTIME
.include "runtime.inc"
.else
.import FPBASE
.endif

.import COMPLM

.export floatAbs

.proc floatAbs
    lda FPBASE + FPMSW
    and #$80                ; Check for high bit in MSB
    beq L1                  ; If not set, jump ahead
    ldx #FPLSW              ; Set pointer
    ldy #3                  ; Three bytes
    jsr COMPLM              ; Negate the accumulator
L1:
    rts
.endproc
