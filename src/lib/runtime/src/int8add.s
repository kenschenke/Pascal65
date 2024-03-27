.include "runtime.inc"

.export addInt8

; Add intOp1 and intOp2, storing the result in intOp1
.proc addInt8
    clc
    lda intOp1
    adc intOp2
    sta intOp1
    rts
.endproc

