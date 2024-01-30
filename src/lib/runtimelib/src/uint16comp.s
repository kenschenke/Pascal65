.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp ltUint16

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
.proc ltUint16
    ; Compare the high bytes first
    lda intOp1 + 1
    cmp intOp2 + 1
    bcc L2
    bne L1

    ; Compare the lower bytes
    lda intOp1
    cmp intOp2
    bcc L2

L1:
    lda #0
    rts

L2:
    lda #1
    rts
.endproc
