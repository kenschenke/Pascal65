.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp ltInt8

; end of exports
.byte $00, $00, $00

; imports

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

; Compare if intOp1 is less than intOp2
; .A contains 1 if intOp1 < intOp2, 0 otherwise.
.proc ltInt8
    lda intOp1
    cmp intOp2
    bvc L1
    eor #$80
L1:
    bpl L2
    lda #1
    rts
L2:
    lda #0
    rts
.endproc

