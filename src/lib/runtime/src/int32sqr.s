.include "runtime.inc"

.export int32Sqr

.import multInt32
; Square the 32-bit integer in intOp1/intOp2, leaving the result in intOp1/intOp2
.proc int32Sqr
    ldx #3
:   lda intOp1,x
    sta intOp32,x
    dex
    bpl :-
    jmp multInt32
.endproc
