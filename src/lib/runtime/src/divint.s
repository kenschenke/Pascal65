;
; divint.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; This routine divides two integers, <operand-1> divided by <operand-2>.
; Both operands are expected on the runtime stack with <operand-1>
; pushed first before <operand-2>.  The result is left at the top of the stack.

; Inputs:
;    A - data type of <operand-1>
;    X - data type of <operand-2>
;    Y - data type of result

.include "runtime.inc"
.include "types.inc"

.export divint

.import prepOperands8, prepOperands16, prepOperands32, prepOperandsReal
.import divInt8, divInt16, divInt32

.proc divint
    cpy #TYPE_BYTE
    beq div8
    cpy #TYPE_SHORTINT
    beq div8
    cpy #TYPE_WORD
    beq div16
    cpy #TYPE_INTEGER
    beq div16
    cpy #TYPE_CARDINAL
    beq div32
    cpy #TYPE_LONGINT
    beq div32
    rts
.endproc

.proc div8
    jsr prepOperands8
    jsr divInt8
    jmp rtPushFromIntOp1
.endproc

.proc div16
    jsr prepOperands16
    jsr divInt16
    jmp rtPushFromIntOp1
.endproc

.proc div32
    jsr prepOperands32
    jsr divInt32
    jmp rtPushFromIntOp1And2
.endproc

