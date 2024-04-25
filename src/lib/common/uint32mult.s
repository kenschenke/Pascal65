;
; uint32mult.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Unsigned 32-bit integer multiplication
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.ifdef RUNTIME
.include "runtime.inc"
.else
.importzp ptr3
.import intOp1, intOp2, intOp32
.endif

.ifdef __MEGA65__
MULTINA = $d770
MULTINB = $d774
MULTOUT = $d778
.endif

.import ltUint32, swapInt32

.export multUint32

.macro isIntOp32NonZero
    lda intOp32
    ora intOp32 + 1
    ora intOp32 + 2
    ora intOp32 + 3
.endmacro

; This routine multiplies intOp1/intOp2 and intOp32, treated as unsigned values.
;
; It orders the operands so the larger of the values is in intOp1/intOp2.
;
; Then it loops and adds intOp1/intOp2 to itself until intOp32 is zero.

.proc multUint32
.ifdef __MEGA65__
    ; Load the first operand
    ldx #3
:   lda intOp1,x
    sta MULTINA,x
    dex
    bpl :-

    ; Load the second operand
    ldx #3
:   lda intOp32,x
    sta MULTINB,x
    dex
    bpl :-

    ; Load the result
    ldx #3
:   lda MULTOUT,x
    sta intOp1,x
    dex
    bpl :-
.else
    ; If intOp1/intOp2 is zero result is zero
    lda intOp1
    ora intOp1 + 1
    ora intOp2
    ora intOp2 + 1
    bne :+
    beq Done
    ; If intOp32 is zero, store zero in result
:   isIntOp32NonZero
    bne L1
    lda #0
    ldx #3
:   sta intOp1,x
    dex
    bpl :-
    bmi Done
L1:
    ; Is the first operand < the second operand?
    jsr ltUint32
    beq :+      ; branch if not
    ; Swap intOp1/intOp2 and intOp32
    jsr swapInt32
    ; Clear the result
:   lda #0
    ldx #3
:   sta ptr3,x
    dex
    bpl :-

    ; Loop until intOp32 is zero, adding intOp1/intOp2 to the result
L2:
    ; Add intOp1/intOp2 to the result
    clc
    ldx #0
    ldy #4
:   lda ptr3,x
    adc intOp1,x
    sta ptr3,x
    inx
    dey
    bne :-
    ; Decrement intOp32 by one
    ldx #0
:   dec intOp32,x
    bpl :+
    inx
    cpx #4
    bne :-
:   isIntOp32NonZero
    bne L2

    ; Store the result in intOp1/intOp2
    ldx #3
:   lda ptr3,x
    sta intOp1,x
    dex
    bpl :-
.endif
Done:
    rts
.endproc
