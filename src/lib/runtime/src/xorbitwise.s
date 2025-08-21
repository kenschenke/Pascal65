;
; xorbitwise.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; This routine performs a bitwise XOR on two numbers.
; Both operands are expected on the runtime stack with <operand-1>
; pushed first before <operand-2>.  The result is left at the top of the stack.

; Inputs:
;    A - data type of <operand-1>
;    X - data type of <operand-2>
;    Y - data type of result

.include "runtime.inc"
.include "types.inc"

.export xorBitwise

.import prepOperands8, prepOperands16, prepOperands32, prepOperandsReal
.import xorInt8, xorInt16, xorInt32

.proc xorBitwise
    cpy #TYPE_BYTE
    beq xor8
    cpy #TYPE_SHORTINT
    beq xor8
    cpy #TYPE_WORD
    beq xor16
    cpy #TYPE_INTEGER
    beq xor16
    cpy #TYPE_CARDINAL
    beq xor32
    cpy #TYPE_LONGINT
    beq xor32
    rts
.endproc

.proc xor8
    jsr prepOperands8
    jsr xorInt8
    jmp rtPushFromIntOp1
.endproc

.proc xor16
    jsr prepOperands16
    jsr xorInt16
    jmp rtPushFromIntOp1
.endproc

.proc xor32
    jsr prepOperands32
    jsr xorInt32
    jmp rtPushFromIntOp1And2
.endproc
