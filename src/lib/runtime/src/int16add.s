.include "runtime.inc"

.export addInt16

; Add intOp1 and intOp2, storing the result in intOp1
.proc addInt16
    clc
    lda intOp1
    adc intOp2
    sta intOp1
    lda intOp1 + 1
    adc intOp2 + 1
    sta intOp1 + 1
    rts
.endproc

