.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp eqInt16
jmp leInt16
jmp ltInt16
jmp geInt16
jmp gtInt16

; end of exports
.byte $00, $00, $00

; imports

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

; Compare intOp1 and intOp2 for equality.
; .A contains 1 if equal, 0 otherwise
.proc eqInt16
    lda intOp1
    cmp intOp2
    bne L1
    lda intOp1 + 1
    cmp intOp2 + 1
    bne L1
    lda #1
    rts
L1:
    lda #0
    rts
.endproc

; Compare if intOp1 less than or equal to intOp2.
; .A contains 1 if intOp1 <= intOp2, 0 otherwise.
.proc leInt16
    jsr eqInt16
    bne L1
    jmp ltInt16
L1:
    lda #1
    rts
.endproc

; Compare if intOp1 is less than intOp2
; .A contains 1 if intOp1 < intOp2, 0 otherwise.
.proc ltInt16
    lda intOp1
    cmp intOp2
    lda intOp1 + 1
    sbc intOp2 + 1
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

; Compare if intOp1 is greather than intOp2
; .A contains 1 if intOp1 > intOp2, 0 otherwise.
.proc gtInt16
    jsr eqInt16
    bne L1
    jmp geInt16
L1:
    lda #0
    rts
.endproc

; Compare if intOp1 is greater than or equal to intOp2.
; .A contains 1 if intOp1 >= intOp2, 0 otherwise.
.proc geInt16
    lda intOp1
    cmp intOp2
    lda intOp1 + 1
    sbc intOp2 + 1
    bvc L1
    eor #$80
L1:
    bpl L2
    lda #0
    rts
L2:
    lda #1
    rts
.endproc

