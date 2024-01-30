.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp multUint16

; end of exports
.byte $00, $00, $00

; imports

ltUint16: jmp $0000
swapInt16: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

; tmp3 - LB result
; tmp4 - HB result
;
; This routine multiplies intOp1 and intOp2, treated as unsigned values.
;
; It orders the operands so the larger of the values is in intOp1.
;
; Then it loops and adds intOp1 to itself until intOp2 is zero.

.proc multUint16
    ; If intOp1 is zero result is zero
    lda intOp1
    ora intOp1 + 1
    beq Done
    ; If intOp2 is zero, store zero in result
    lda intOp2
    ora intOp2 + 1
    bne :+
    lda #0
    sta intOp1
    sta intOp1 + 1
    beq Done
    ; Take the absolute value of intOp1
:
    ; Is intOp1 < intOp2
    jsr ltUint16
    beq :+         ; swap them
    ; Swap intOp1 and intOp2
    jsr swapInt16

    ; Zero out the result
:   lda #0
    sta tmp3
    sta tmp4

    ; Loop until intOp2 is zero, adding intOp1 to result
L1:
    clc
    lda tmp3
    adc intOp1
    sta tmp3
    lda tmp4
    adc intOp1 + 1
    sta tmp4
    ; Subtract one from intOp2
    dec intOp2
    bpl :+
    dec intOp2 + 1
:   lda intOp2
    ora intOp2 + 1
    bne L1

    ; Store the result in intOp1
    lda tmp3
    sta intOp1
    lda tmp4
    sta intOp1 + 1

Done:
    rts
.endproc
