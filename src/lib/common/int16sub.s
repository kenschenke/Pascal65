.ifdef RUNTIME
.include "runtime.inc"
.else
.import intOp1, intOp2
.endif
.export subInt16

; Subtract intOp2 from intOp1, storing the result in intOp1
.proc subInt16
    sec
    lda intOp1
    sbc intOp2
    sta intOp1
    lda intOp1 + 1
    sbc intOp2 + 1
    sta intOp1 + 1
    rts
.endproc

