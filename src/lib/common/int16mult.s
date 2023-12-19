.ifdef RUNTIME
.include "runtime.inc"
.else
.importzp tmp1, tmp2, tmp3, tmp4
.import intOp1, intOp2
.endif

.import absInt16, invertInt16, ltInt16, swapInt16

.export multInt16

.proc reloadIntOps
    lda tmp1
    sta intOp1
    lda tmp2
    sta intOp1 + 1
    lda tmp3
    sta intOp2
    lda tmp4
    sta intOp2 + 1
    rts
.endproc

; tmp2 - op2 is negative
; tmp3 - LB result
; tmp4 - HB result
;
; This routine multiplies two signed 16-bit integers stored in intOp1 and intOp2.
; The result is stored in intOp1.  It does not check for overflow.
;
; It orders the operands so the larger of the absolute values is in intOp1.
;
; Then it looks at intOp2 and, if negative, changes it to the absolute value.
;
; Then it loops and adds intOp1 to itself until intOp2 is zero.
;
; Finally, if intOp2 was negative, it inverts the sign on the result.

.proc multInt16
    ; Store intOp1 in tmp1/tmp2
    lda intOp1
    sta tmp1
    lda intOp1 + 1
    sta tmp2
    ; Store intOp2 in tmp3/tmp4
    lda intOp2
    sta tmp3
    lda intOp2 + 1
    sta tmp4
    ; If intOp1 is zero result is zero
    lda intOp1
    ora intOp1 + 1
    bne L0
    jmp Done
L0:
    ; If intOp2 is zero, store zero in result
    lda intOp2
    ora intOp2 + 1
    bne L1
    lda #0
    sta intOp1
    sta intOp1 + 1
    jmp Done
    ; Take the absolute value of intOp1
L1:
    jsr absInt16
    ; Store it in intOp2
    lda intOp1
    sta intOp2
    lda intOp1 + 1
    sta intOp2 + 1
    ; Take the absolute value of intOp2
    lda tmp3
    sta intOp1
    lda tmp4
    sta intOp1 + 1
    jsr absInt16
    ; Is intOp1 < intOp2
    jsr ltInt16
    beq L2         ; swap them
    jsr reloadIntOps
    jmp L3
L2:
    ; Swap intOp1 and intOp2
    jsr reloadIntOps
    jsr swapInt16
L3:
    ; Is intOp2 negative?
    lda #0
    sta tmp2
    lda intOp2 + 1
    and #$80
    beq L4              ; not negative
    lda #1
    sta tmp2
    ; Invert intOp2
    jsr swapInt16
    jsr invertInt16
    jsr swapInt16

L4:
    lda #0
    sta tmp3
    sta tmp4

    ; Loop until intOp2 is zero, adding intOp1 to result
L5:
    clc
    lda tmp3
    adc intOp1
    sta tmp3
    lda tmp4
    adc intOp1 + 1
    sta tmp4
    ; Subtract one from intOp2
    sec
    lda intOp2
    sbc #1
    sta intOp2
    lda intOp2 + 1
    sbc #0
    sta intOp2 + 1
    ; Is intOp2 zero?
    lda intOp2
    ora intOp2 + 1
    bne L5

    ; Store the result in intOp1
    lda tmp3
    sta intOp1
    lda tmp4
    sta intOp1 + 1

    ; Do we need to negatate the result?
    lda tmp2
    beq Done
    jsr invertInt16     ; Yes

Done:
    rts
.endproc
