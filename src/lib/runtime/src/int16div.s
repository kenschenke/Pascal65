;
; int16div.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "error.inc"
.include "runtime.inc"

.export divInt16

.import absInt16, invertInt16, isNegInt16, ltInt16, swapInt16

; tmp1 - intOpt1 is -32768
; tmp2 - result is negative
; tmp3 - LB result
; tmp4 - HB result
;
; This routine divides two signed 16-bit integers stored in intOp1 and intOp2.
; The result is stored in intOp1.
;
; The routine first checks to see if either operand is zero and shortcuts out if so.
;
; If intOp1 or intOp2 is negative (but not both), the result will be negative.
;
; If intOp1 is -32768, one is added before taking the absolute value.  In the first
; iteration through the loop, one is added back into intOp1.
;
; It then takes the absolute value of both operands.
;
; Then it loops and subtracts intOp2 from intOp1 until intOp1 is less than intOp2.
; The number of subtractions becomes the result.
;
; Finally, if the result is negative, it inverts the sign on the result.

.proc divInt16
    ; Check for divide by zero
    lda intOp2
    ora intOp2 + 1
    bne DividendCheck
    ; Divide by zero
    lda #rteDivisionByZero
    jmp rtRuntimeError

DividendCheck:
    ; Special case - dividend is zero
    lda intOp1
    ora intOp1 + 1
    bne L1            ; is intOp1 zero?

    ; op1 and/or op2 is zero.  Result is zero.
    lda #0
    sta intOp1
    sta intOp1 + 1
    rts

L1:
    lda #0
    sta tmp3
    sta tmp4
    ; Is op1 negative?
    jsr isNegInt16      ; check if op1 is negative
    beq L2
    lda #1              ; it is.  store 1 in tmp3
    sta tmp3
L2:
    ; Is op2 negative?
    lda intOp2 + 1
    and #$80
    beq L3              ; not negative
    lda #1              ; it's negative.  store 1 in tmp4
    sta tmp4
L3:
    ; if either op1 is negative or op2 is negative,
    ; leave a 1 in tmp2.  if both are positive or
    ; both are negative, leave 1 0 in tmp2.
    lda tmp3
    eor tmp4
    sta tmp2

    ; Is op1 -32768?
    ; If so, we can't take the absolute value so 1 is added,
    ; making it -32767.  This is done because the division
    ; operation is done on positive numbers to make the
    ; math easier.  We store a 1 in tmp1 if we do this so
    ; we can remember to add 1 back to the result later.
    lda #0
    sta tmp1
    lda intOp1
    cmp #0
    bne L4
    lda intOp1 + 1
    cmp #$80
    bne L4

    ; intOp1 is -32768
    lda #1
    sta tmp1            ; store 1 in tmp1
    ; Add one to intOp1
    clc
    lda intOp1
    adc #1
    sta intOp1
    lda intOp1 + 1
    adc #0
    sta intOp1 + 1

L4:
    ; Take the absolute values of intOp1 and intOp2
    jsr absInt16        ; absolute value of intOp1
    jsr swapInt16       ; swap op1 and op2
    jsr absInt16        ; absolute value of intOp1
    jsr swapInt16       ; swap back

    ; Initialize result
    lda #0
    sta tmp3
    sta tmp4

    ; Loop until intOp1 is less than intOp2
L5:
    jsr ltInt16         ; Is op1 < op2?
    cmp #0
    bne L6              ; It is.
    ; Subtract op2 from op1
    sec
    lda intOp1
    sbc intOp2
    sta intOp1
    lda intOp1 + 1
    sbc intOp2 + 1
    sta intOp1 + 1
    ; Increment tmp3/tmp4
    clc
    lda tmp3
    adc #1
    sta tmp3
    lda tmp4
    adc #0
    sta tmp4
    ; Is tmp1 non-zero?
    lda tmp1
    beq L5
    ; Add one to intOp1
    clc
    lda intOp1
    adc #1
    sta intOp1
    lda intOp1 + 1
    adc #0
    sta intOp1 + 1
    lda #0
    sta tmp1
    ; Go again
    beq L5

L6:
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

