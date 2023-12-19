.ifdef RUNTIME
.include "runtime.inc"
.else
.importzp tmp1, ptr1, ptr2, ptr3, ptr4, sreg
.import intOp1, intOp2, intOp32
.endif

.import absInt32, invertInt32, ltInt32, swapInt32

.export multInt32

.import popeax
.export _testMultInt32
.proc _testMultInt32
    sta intOp32
    stx intOp32 + 1
    lda sreg
    sta intOp32 + 2
    lda sreg + 1
    sta intOp32 + 3
    jsr popeax
    sta intOp1
    stx intOp1 + 1
    lda sreg
    sta intOp2
    lda sreg + 1
    sta intOp2 + 1
    jsr multInt32
    lda intOp2
    sta sreg
    lda intOp2 + 1
    sta sreg + 1
    lda intOp1
    ldx intOp1 + 1
    rts
.endproc

.proc reloadIntOps
    lda ptr1
    sta intOp1
    lda ptr1 + 1
    sta intOp1 + 1
    lda ptr2
    sta intOp2
    lda ptr2 + 1
    sta intOp2 + 1
    lda ptr3
    sta intOp32
    lda ptr3 + 1
    sta intOp32 + 1
    lda ptr4
    sta intOp32 + 2
    lda ptr4 + 1
    sta intOp32 + 3
    rts
.endproc

.proc isIntOp32NonZero
    lda intOp32
    ora intOp32 + 1
    ora intOp32 + 2
    ora intOp32 + 3
    rts
.endproc

; tmp1 - op2 is negative
;
; This routine multiplies two signed 32-bit integers stored in intOp1/intOp2 and intOp32.
; The result is stored in intOp1/intOp2.  It does not check for overflow.
;
; It orders the operands so the larger of the absolute values is in intOp1/intOp2.
;
; Then it looks at intOp32 and, if negative, changes it to the absolute value.
;
; Then it loops and adds intOp1/intOp2 to itself until intOp32 is zero.
;
; Finally, if intOp32 was negative, it inverts the sign on the result.

.proc multInt32
    ; Store intOp1/intOp2 in ptr1/ptr2 and intOp32 in ptr3/ptr4
    ldx #7
:   lda intOp1,x
    sta ptr1,x
    dex
    bpl :-
    ; If intOp1/intOp2 is zero result is zero
    lda intOp1
    ora intOp1 + 1
    ora intOp2
    ora intOp2 + 1
    bne :+
    jmp Done
    ; If intOp32 is zero, store zero in result
:   jsr isIntOp32NonZero
    bne L1
    lda #0
    ldx #3
:   sta intOp1,x
    dex
    bpl :-
    jmp Done
    ; Take the absolute value of intOp1/intOp2
L1:
    jsr absInt32
    ; Store it in intOp32
    ldx #3
:   lda intOp1,x
    sta intOp32,x
    dex
    bpl :-
    ; Take the absolute value of intOp32
    ldx #3
:   lda ptr3,x
    sta intOp1,x
    dex
    bpl :-
    jsr absInt32
    ; Is intOp1/intOp2 < intOp32
    jsr ltInt32
    beq L2         ; swap them
    jsr reloadIntOps
    jmp L3
L2:
    ; Swap intOp1/intOp2 and intOp32
    jsr reloadIntOps
    jsr swapInt32
L3:
    ; Is intOp32 negative?
    lda #0
    sta tmp1
    lda intOp32 + 3
    and #$80
    beq L4              ; not negative
    lda #1
    sta tmp1
    ; Invert intOp32
    jsr swapInt32
    jsr invertInt32
    jsr swapInt32

L4:
    lda #0
    sta ptr3
    sta ptr3 + 1
    sta ptr4
    sta ptr4 + 1

    ; Loop until intOp32 is zero, adding intOp1/intOp2 to the result
L5:
    clc
    lda ptr3
    adc intOp1
    sta ptr3
    lda ptr3 + 1
    adc intOp1 + 1
    sta ptr3 + 1
    lda ptr4
    adc intOp2
    sta ptr4
    lda ptr4 + 1
    adc intOp2 + 1
    sta ptr4 + 1
    ; Subtract one from intOp32
    sec
    lda intOp32
    sbc #1
    sta intOp32
    lda intOp32 + 1
    sbc #0
    sta intOp32 + 1
    lda intOp32 + 2
    sbc #0
    sta intOp32 + 2
    lda intOp32 + 3
    sbc #0
    sta intOp32 + 3
    ; Is intOp32 zero?
    jsr isIntOp32NonZero
    bne L5

    ; Store the result in intOp1/intOp2
    ldx #3
:   lda ptr3,x
    sta intOp1,x
    dex
    bpl :-

    ; Do we need to negatate the result?
    lda tmp1
    beq Done
    jsr invertInt32     ; Yes

Done:
    rts
.endproc
