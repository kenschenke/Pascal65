.include "runtime.inc"

.export subInt8

; Subtract intOp2 from intOp1, storing the result in intOp1
.proc subInt8
    sec
    lda intOp1
    sbc intOp2
    sta intOp1
    rts
.endproc

