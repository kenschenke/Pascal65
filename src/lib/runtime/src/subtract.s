;
; subtract.s
; Ken Schenke (kenschenke@gmail.com)
;
; Integer subtraction
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;

; This routine subtracts two numbers, <operand-2> from <operand-1>.
; Both operands are expected on the runtime stack with <operand-1>
; pushed first before <operand-2>.  The result is left at the top of the stack.

; Inputs:
;    A - data type of <operand-1>
;    X - data type of <operand-2>
;    Y - data type of result

.include "runtime.inc"
.include "types.inc"

.export subtract

.import prepOperands8, prepOperands16, prepOperands32, prepOperandsReal
.import subInt8, subInt16, subInt32, FPSUB

.code

.proc subtract
    cpy #TYPE_BYTE
    beq sub8
    cpy #TYPE_SHORTINT
    beq sub8
    cpy #TYPE_WORD
    beq sub16
    cpy #TYPE_INTEGER
    beq sub16
    cpy #TYPE_CARDINAL
    beq sub32
    cpy #TYPE_LONGINT
    beq sub32
    cpy #TYPE_REAL
    beq subReal
    rts
.endproc

.proc sub8
    jsr prepOperands8
    jsr subInt8
    jmp rtPushFromIntOp1
.endproc

.proc sub16
    jsr prepOperands16
    jsr subInt16
    jmp rtPushFromIntOp1
.endproc

.proc sub32
    jsr prepOperands32
    jsr subInt32
    jmp rtPushFromIntOp1And2
.endproc

.proc subReal
    jsr prepOperandsReal
    jsr FPSUB
    jmp rtPushReal
.endproc
