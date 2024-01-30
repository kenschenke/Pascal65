.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp addInt32

; end of exports
.byte $00, $00, $00

; imports

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

; Add intOpt1/intOp2 to intOp32, storing the result in intOp1/intOp2
;    intOp1 contains the lower 2 bytes of the first operand and
;    intOp2 contains the upper 2 bytes.
;    intOp32 contains the other operand.
.proc addInt32
    clc
    lda intOp1
    adc intOp32
    sta intOp1
    lda intOp1 + 1
    adc intOp32 + 1
    sta intOp1 + 1
    lda intOp2
    adc intOp32 + 2
    sta intOp2
    lda intOp2 + 1
    adc intOp32 + 3
    sta intOp2 + 1
    rts
.endproc

