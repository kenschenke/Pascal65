.include "float.inc"
.include "runtime.inc"

.export floatAbs

.import floatNeg

.proc floatAbs
    lda FPBASE + FPMSW
    and #$80                ; Check for high bit in MSB
    beq L1                  ; If not set, jump ahead
    jmp floatNeg
L1:
    rts
.endproc
