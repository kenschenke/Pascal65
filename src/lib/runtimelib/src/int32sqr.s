.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp int32Sqr

; end of exports
.byte $00, $00, $00

; imports

multInt32: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

; Square the 32-bit integer in intOp1/intOp2, leaving the result in intOp1/intOp2
.proc int32Sqr
    ldx #3
:   lda intOp1,x
    sta intOp32,x
    dex
    bpl :-
    jmp multInt32
.endproc
