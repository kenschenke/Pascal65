.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp subInt8

; end of exports
.byte $00, $00, $00

; imports

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

; Subtract intOp2 from intOp1, storing the result in intOp1
.proc subInt8
    sec
    lda intOp1
    sbc intOp2
    sta intOp1
    rts
.endproc

