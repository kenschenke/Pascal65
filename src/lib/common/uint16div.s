;
; uint16div.s
; Ken Schenke (kenschenke@gmail.com)
; 
; 16-bit integer division
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "error.inc"

.ifdef RUNTIME
.include "runtime.inc"
.else
.importzp tmp3, tmp4
.import intOp1, intOp2
.endif

.import ltUint16
.import runtimeError, exit

.ifdef __MEGA65__
MULTINA = $d770
MULTINB = $d774
MULTOUT = $d778
DIVBUSY = $d70f
DIVOUT = $d76c
.endif

.export divUint16

; tmp3 - LB result
; tmp4 - HB result
;
; This routine divides two unsigned 16-bit integers stored in intOp1 and intOp2.
; The result is stored in intOp1.
;
; The routine first checks to see if either operand is zero and shortcuts out if so.
;
; Then it loops and subtracts intOp2 from intOp1 until intOp1 is less than intOp2.
; The number of subtractions becomes the result.

.proc divUint16
    ; Check for divide by zero
    lda intOp2
    ora intOp2 + 1
    bne DividendCheck
    ; Divide by zero
    lda #rteDivisionByZero
    jmp runtimeError

DividendCheck:
    ; Special case - dividend is zero
    lda intOp1
    ora intOp1 + 1
    beq Done            ; is intOp1 zero?

.ifdef __MEGA65__
    lda intOp1
    sta MULTINA
    lda intOp1 + 1
    sta MULTINA + 1
    lda intOp2
    sta MULTINB
    lda intOp2 + 1
    sta MULTINB + 1
    lda #0
    sta MULTINA + 2
    sta MULTINA + 3
    sta MULTINB + 2
    sta MULTINB + 3
:   bit DIVBUSY
    bmi :-
    lda DIVOUT
    sta intOp1
    lda DIVOUT + 1
    sta intOp1 + 1
.else
L1:
    ; Initialize the result
    lda #0
    sta tmp3
    sta tmp4

    ; Loop until intOp1 is less than intOp2
L5:
    jsr ltUint16         ; Is op1 < op2?
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
    inc tmp3
    bne L5
    inc tmp4
    ; Go again
:   jmp L5

L6:
    ; Store the result in intOp1
    lda tmp3
    sta intOp1
    lda tmp4
    sta intOp1 + 1
.endif

Done:
    rts
.endproc

