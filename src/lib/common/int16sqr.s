.ifdef RUNTIME
.include "runtime.inc"
.else
.import intOp1, intOp2
.endif

.import multInt16
.export int16Sqr

; Square the integer in intOp1, leaving the result in intOp1
.proc int16Sqr
    lda intOp1
    sta intOp2
    lda intOp1 + 1
    sta intOp2 + 1
    jmp multInt16
.endproc
