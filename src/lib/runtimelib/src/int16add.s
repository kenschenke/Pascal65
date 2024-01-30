.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp addInt16

; end of exports
.byte $00, $00, $00

; imports

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

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

