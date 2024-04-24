;
; rshiftbitwise.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; This routine performs a bitwise right shift.
; The operands are expected on the runtime stack with <operand-1>
; pushed first before <operand-2>.  The result is left at the top of the stack.
; <operand-1> is the number being shifted and <operand-2> is the number of times
; to shift the number.

; Inputs:
;    A - data type of <operand-1>
;    Y - data type of result

.include "runtime.inc"
.include "types.inc"

.export rshiftBitwise

.import prepOperands8, prepOperands16, prepOperands32, prepOperandsReal
.import rshiftInt8, rshiftInt16, rshiftInt32

.proc rshiftBitwise
    cpy #TYPE_BYTE
    beq rshift8
    cpy #TYPE_SHORTINT
    beq rshift8
    cpy #TYPE_WORD
    beq rshift16
    cpy #TYPE_INTEGER
    beq rshift16
    cpy #TYPE_CARDINAL
    beq rshift32
    cpy #TYPE_LONGINT
    beq rshift32
    rts
.endproc

.proc rshift8
    ldx #TYPE_BYTE
    jsr prepOperands8
    lda intOp2
    jsr rshiftInt8
    jmp rtPushFromIntOp1
.endproc

.proc rshift16
    ldx #TYPE_BYTE
    jsr prepOperands16
    lda intOp2
    jsr rshiftInt16
    jmp rtPushFromIntOp1
.endproc

.proc rshift32
    ldx #TYPE_BYTE
    jsr prepOperands32
    lda intOp32
    jsr rshiftInt32
    jmp rtPushFromIntOp1And2
.endproc
