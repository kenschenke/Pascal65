.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp subInt32

; end of exports
.byte $00, $00, $00

; imports

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

; Subtract intOp32 from intOp1/intOp2, storing the result in intOp1/intOp2
.proc subInt32
    sec
    lda intOp1
    sbc intOp32
    sta intOp1
    lda intOp1 + 1
    sbc intOp32 + 1
    sta intOp1 + 1
    lda intOp2
    sbc intOp32 + 2
    sta intOp2
    lda intOp2 + 1
    sbc intOp32 + 3
    sta intOp2 + 1
    rts
.endproc

