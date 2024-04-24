;
; lshiftbitwise.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; This routine performs a bitwise left shift.
; The operands are expected on the runtime stack with <operand-1>
; pushed first before <operand-2>.  The result is left at the top of the stack.
; <operand-1> is the number being shifted and <operand-2> is the number of times
; to shift the number.

; Inputs:
;    A - data type of <operand-1>
;    Y - data type of result

.include "runtime.inc"
.include "types.inc"

.export lshiftBitwise

.import prepOperands8, prepOperands16, prepOperands32, prepOperandsReal
.import lshiftInt8, lshiftInt16, lshiftInt32

.proc lshiftBitwise
    cpy #TYPE_BYTE
    beq lshift8
    cpy #TYPE_SHORTINT
    beq lshift8
    cpy #TYPE_WORD
    beq lshift16
    cpy #TYPE_INTEGER
    beq lshift16
    cpy #TYPE_CARDINAL
    beq lshift32
    cpy #TYPE_LONGINT
    beq lshift32
    rts
.endproc

.proc lshift8
    ldx #TYPE_BYTE
    jsr prepOperands8
    lda intOp2
    jsr lshiftInt8
    jmp rtPushFromIntOp1
.endproc

.proc lshift16
    ldx #TYPE_BYTE
    jsr prepOperands16
    lda intOp2
    jsr lshiftInt16
    jmp rtPushFromIntOp1
.endproc

.proc lshift32
    ldx #TYPE_BYTE
    jsr prepOperands32
    lda intOp32
    jsr lshiftInt32
    jmp rtPushFromIntOp1And2
.endproc
