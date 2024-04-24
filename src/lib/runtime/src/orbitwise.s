;
; orbitwise.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; This routine performs a bitwise OR on two numbers.
; Both operands are expected on the runtime stack with <operand-1>
; pushed first before <operand-2>.  The result is left at the top of the stack.

; Inputs:
;    A - data type of <operand-1>
;    X - data type of <operand-2>
;    Y - data type of result

.include "runtime.inc"
.include "types.inc"

.export orBitwise

.import prepOperands8, prepOperands16, prepOperands32, prepOperandsReal
.import orInt8, orInt16, orInt32

.proc orBitwise
    cpy #TYPE_BYTE
    beq or8
    cpy #TYPE_SHORTINT
    beq or8
    cpy #TYPE_WORD
    beq or16
    cpy #TYPE_INTEGER
    beq or16
    cpy #TYPE_CARDINAL
    beq or32
    cpy #TYPE_LONGINT
    beq or32
    rts
.endproc

.proc or8
    jsr prepOperands8
    jsr orInt8
    jmp rtPushFromIntOp1
.endproc

.proc or16
    jsr prepOperands16
    jsr orInt16
    jmp rtPushFromIntOp1
.endproc

.proc or32
    jsr prepOperands32
    jsr orInt32
    jmp rtPushFromIntOp1And2
.endproc
