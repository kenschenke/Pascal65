;
; andbitwise.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; This routine performs a bitwise AND on two numbers.
; Both operands are expected on the runtime stack with <operand-1>
; pushed first before <operand-2>.  The result is left at the top of the stack.

; Inputs:
;    A - data type of <operand-1>
;    X - data type of <operand-2>
;    Y - data type of result

.include "runtime.inc"
.include "types.inc"

.export andBitwise

.import prepOperands8, prepOperands16, prepOperands32, prepOperandsReal
.import andInt8, andInt16, andInt32

.proc andBitwise
    cpy #TYPE_BYTE
    beq and8
    cpy #TYPE_SHORTINT
    beq and8
    cpy #TYPE_WORD
    beq and16
    cpy #TYPE_INTEGER
    beq and16
    cpy #TYPE_CARDINAL
    beq and32
    cpy #TYPE_LONGINT
    beq and32
    rts
.endproc

.proc and8
    jsr prepOperands8
    jsr andInt8
    jmp rtPushFromIntOp1
.endproc

.proc and16
    jsr prepOperands16
    jsr andInt16
    jmp rtPushFromIntOp1
.endproc

.proc and32
    jsr prepOperands32
    jsr andInt32
    jmp rtPushFromIntOp1And2
.endproc
