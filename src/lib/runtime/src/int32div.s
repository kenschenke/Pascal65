;
; int32div.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "error.inc"
.include "runtime.inc"

.ifdef __MEGA65__
MULTINA = $d770
MULTINB = $d774
MULTOUT = $d778
DIVBUSY = $d70f
DIVOUT = $d76c
.endif

.export divInt32

.import absInt32, invertInt32, isNegInt32, ltInt32, swapInt32, runtimeError

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
    ldx #0
:   inc intOp1,x
    bne L4
    inx
    cpx #4
    bne :-

L4:
    ; Take the absolute values of intOp1/intOp2 and intOp32
    jsr absInt32        ; absolute value of intOp1/intOp2
    jsr swapInt32       ; swap op1 and op2
    jsr absInt32        ; absolute value of intOp32
    jsr swapInt32       ; swap back

.ifdef __MEGA65__
    ldx #3
:   lda intOp1,x
    sta MULTINA,x
    lda intOp32,x
    sta MULTINB,x
    dex
    bpl :-
:   bit DIVBUSY
    bmi :-
    ldx #3
:   lda DIVOUT,x
    sta intOp1,x
    dex
    bpl :-
.else
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
    ldx #0
    ldy #4
:   lda intOp1,x
    sbc intOp32,x
    sta intOp1,x
    inx
    dey
    bne :-
    ; Increment ptr1/ptr2
    ldx #0
:   inc ptr1,x
    bne :+
    inx
    cpx #4
    bne :-
    ; Is tmp1 non-zero?
:   lda tmp1
    beq L5
    ; Add one to intOp1/intOp2
    ldx #0
:   inc intOp1,x
    bne :+
    inx
    cpx #4
    bne :-
:   lda #0
    sta tmp1
    ; Go again
    beq L5

L6:
    ; Store the result in intOp1/intOp2
    ldx #3
:   lda ptr1,x
    sta intOp1,x
    dex
    bpl :-
.endif

    ; Do we need to negatate the result?
    lda tmp2
    beq Done
    jsr invertInt32     ; Yes

Done:
    rts
.endproc

