.include "error.inc"
.include "runtime.inc"

.export divUint8

; tmp3 - result
;
; This routine divides two unsigned 8-bit integers stored in intOp1 and intOp2.
; The result is stored in intOp1.
;
; The routine first checks to see if either operand is zero and shortcuts out if so.
;
; Then it loops and subtracts intOp2 from intOp1 until intOp1 is less than intOp2.
; The number of subtractions becomes the result.

.proc divUint8
    ; Check for divide by zero
    lda intOp2
    bne L1
    ; Divide by zero
    lda #rteDivisionByZero
    jmp rtRuntimeError

L1:
    ; Special case - dividend is zero
    lda intOp1
    beq Done

    ; Initialize result
    lda #0
    sta tmp3

    ; Loop until intOp1 is less than intOp2
L2:
    lda intOp1
    cmp intOp2         ; Is op1 < op2
    bcc L3             ; Branch if it is
    ; Subtract op2 from op1
    sec
    lda intOp1
    sbc intOp2
    sta intOp1
    ; Increment tmp3
    inc tmp3
    ; Go again
    jmp L2

L3:
    ; Store the result in intOp1
    lda tmp3
    sta intOp1

Done:
    rts
.endproc

