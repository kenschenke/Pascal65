.include "error.inc"

.import divInt16, intOp1, intOp2, multInt16, swapInt16, subInt16, runtimeError

.export modInt16

; This routine finds the remainder (mod) of dividing intOp1 by intOp2.
; It checks for mod 0 (divide by zero).
;
; 1.  Divide intOp1 by intOp2
; 2.  Multiply answer by intOp2
; 3.  Subtract answer from intOp1
; 4.  Result is remainder

.proc modInt16
    ; Check for divide by zero
    lda intOp2
    ora intOp2 + 1
    bne L1
    lda #rteDivisionByZero
    jmp runtimeError
L1:
    ; Push intOp1 and intOp2 onto stack
    lda intOp1
    pha
    lda intOp1 + 1
    pha
    lda intOp2
    pha
    lda intOp2 + 1
    pha
    ; Step 1
    jsr divInt16
    ; Pull intOp2 from stack
    pla
    sta intOp2 + 1
    pla
    sta intOp2
    ; Step 2
    jsr multInt16
    ; Swap op1 and op2
    jsr swapInt16
    ; Pull intOp1 from stack
    pla
    sta intOp1 + 1
    pla
    sta intOp1
    ; Step 3
    jsr subInt16
    ; Step 4 - remainder is in intOp1
    rts
.endproc
