;
; uint32div.s
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

.export divUint32

.import ltInt32

; ptr1/ptr2 - result
;
; This routine divides two unsigned 32-bit integers stored in intOp1/intOp2 and intOp32.
; The result is stored in intOp1/intOp2.
;
; The routine first checks to see if either operand is zero and shortcuts out if so.
;
; Then it loops and subtracts intOp32 from intOp1/intOp2 until intOp1/intOp2 is less than intOp32.
; The number of subtractions becomes the result.

.proc divUint32
    ; Check for divide by zero
    lda intOp32
    ora intOp32 + 1
    ora intOp32 + 2
    ora intOp32 + 3
    bne DividendCheck
    ; Divide by zero
    lda #rteDivisionByZero
    jmp rtRuntimeError

DividendCheck:
    ; Special case - dividend is zero
    lda intOp1
    ora intOp1 + 1
    ora intOp2
    ora intOp2 + 1
    beq Done            ; is intOp1/intOp2 zero?

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
    ; Go again
    jmp L5

L6:
    ; Store the result in intOp1/intOp2
    ldx #3
:   lda ptr1,x
    sta intOp1,x
    dex
    bpl :-
.endif

Done:
    rts
.endproc

