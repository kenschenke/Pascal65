.include "error.inc"

.ifdef RUNTIME
.include "runtime.inc"
.else
.importzp tmp1, tmp2, tmp3, tmp4, ptr1, ptr2
.import intOp1, intOp2, intOp32
.endif

.import absInt32, invertInt32, isNegInt32, ltInt32, swapInt32
.import runtimeError, exit

.export divInt32

.import popeax
.export _testDivInt32
.ifndef RUNTIME
.importzp sreg
.endif

; tmp1 - intOpt1 is -32768
; tmp2 - result is negative
; tmp3 - non-zero if dividend is negative
; tmp4 - non-zero if divisor is negative
; ptr1/ptr2 - result
;
; This routine divides two signed 32-bit integers stored in intOp1/intOp2 and intOp32.
; The result is stored in intOp1/intOp2.
;
; The routine first checks to see if either operand is zero and shortcuts out if so.
;
; If either operand is negative (but not both), the result will be negative.
;
; If intOp1/intOp2 is -2147483648, one is added before taking the absolute value.  In the first
; iteration through the loop, one is added back into intOp1/intOp2.
;
; It then takes the absolute value of both operands.
;
; Then it loops and subtracts intOp32 from intOp1/intOp2 until intOp1/intOp2 is less than intOp32.
; The number of subtractions becomes the result.
;
; Finally, if the result is negative, it inverts the sign on the result.

.proc _testDivInt32
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
    jsr divInt32
    lda intOp2
    sta sreg
    lda intOp2 + 1
    sta sreg + 1
    lda intOp1
    ldx intOp1 + 1
    rts
.endproc

.proc divInt32
    ; Check for divide by zero
    lda intOp32
    ora intOp32 + 1
    ora intOp32 + 2
    ora intOp32 + 3
    bne DividendCheck
    ; Divide by zero
    lda #rteDivisionByZero
    jmp runtimeError

DividendCheck:
    ; Special case - dividend is zero
    lda intOp1
    ora intOp1 + 1
    ora intOp2
    ora intOp2 + 1
    bne L1            ; is intOp1/intOp2 zero?

    ; dividend is zero.  Result is zero.
    lda #0
    ldx #3
:   sta intOp1,x
    dex
    bpl :-
    rts

L1:
    lda #0
    sta tmp3
    sta tmp4
    ; Is the first operand negative?
    jsr isNegInt32      ; check if op1/op2 is negative
    beq L2
    lda #1              ; it is.  store 1 in tmp3
    sta tmp3
L2:
    ; Is the divisor negative?
    lda intOp32 + 3
    and #$80
    beq L3              ; not negative
    lda #1              ; it's negative.  store 1 in tmp4
    sta tmp4
L3:
    ; if either the dividend is negative or the divisor is negative,
    ; leave a 1 in tmp2.  if both are positive or
    ; both are negative, leave 1 0 in tmp2.
    lda tmp3
    eor tmp4
    sta tmp2

    ; Is the dividend -2147483648?
    ; If so, we can't take the absolute value so 1 is added,
    ; making it -2147483647.  This is done because the division
    ; operation is done on positive numbers to make the
    ; math easier.  We store a 1 in tmp1 if we do this so
    ; we can remember to add 1 back to the result later.
    lda #0
    sta tmp1
    ldx #2
:   lda intOp32,x
    bne L4
    dex
    bpl :-
    lda intOp32 + 3
    cmp #$80
    bne L4

    ; intOp1 is -2147483647
    lda #1
    sta tmp1            ; store 1 in tmp1
    ; Add one to intOp1/intOp2
    clc
    lda intOp1
    adc #1
    sta intOp1
    lda intOp1 + 1
    adc #0
    sta intOp1 + 1
    lda intOp2
    adc #0
    sta intOp2
    lda intOp2 + 1
    adc #0
    sta intOp2 + 1

L4:
    ; Take the absolute values of intOp1/intOp2 and intOp32
    jsr absInt32        ; absolute value of intOp1/intOp2
    jsr swapInt32       ; swap op1 and op2
    jsr absInt32        ; absolute value of intOp32
    jsr swapInt32       ; swap back

    ; Initialize result
    lda #0
    sta ptr1
    sta ptr1 + 1
    sta ptr2
    sta ptr2 + 1

    ; Loop until intOp1/intOp2 is less than intOp32
L5:
    jsr ltInt32         ; Is op1 < op2?
    cmp #0
    bne L6              ; It is.
    ; Subtract op32 from op1/op2
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
    ; Increment ptr1/ptr2
    clc
    lda ptr1
    adc #1
    sta ptr1
    lda ptr1 + 1
    adc #0
    sta ptr1 + 1
    lda ptr2
    adc #0
    sta ptr2
    lda ptr2 + 1
    adc #0
    sta ptr2 + 2
    ; Is tmp1 non-zero?
    lda tmp1
    beq L5
    ; Add one to intOp1/intOp2
    clc
    lda intOp1
    adc #1
    sta intOp1
    lda intOp1 + 1
    adc #0
    sta intOp1 + 1
    lda intOp2
    adc #0
    sta intOp2
    lda intOp2 + 1
    adc #0
    sta intOp2 + 1
    lda #0
    sta tmp1
    ; Go again
    jmp L5

L6:
    ; Store the result in intOp1/intOp2
    ldx #3
:   lda ptr1,x
    sta intOp1,x
    dex
    bpl :-

    ; Do we need to negatate the result?
    lda tmp2
    beq Done
    jsr invertInt32     ; Yes

Done:
    rts
.endproc

