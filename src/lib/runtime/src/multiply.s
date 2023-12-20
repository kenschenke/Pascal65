; This routine multiplies two numbers, <operand-1> and <operand-2>.
; Both operands are expected on the runtime stack with <operand-1>
; pushed first before <operand-2>.  The result is left at the top of the stack.

; Inputs:
;    A - data type of <operand-1>
;    X - data type of <operand-2>
;    Y - data type of result

.include "types.inc"

.export multiply

.import prepOperands8, prepOperands16, prepOperands32, prepOperandsReal
.import multInt8, multInt16, multInt32, FPMULT
.import pushFromIntOp1, pushFromIntOp1And2, pushRealStack

.proc multiply
    cpy #TYPE_BYTE
    beq mult8
    cpy #TYPE_SHORTINT
    beq mult8
    cpy #TYPE_WORD
    beq mult16
    cpy #TYPE_INTEGER
    beq mult16
    cpy #TYPE_CARDINAL
    beq mult32
    cpy #TYPE_LONGINT
    beq mult32
    cpy #TYPE_REAL
    beq multReal
    rts
.endproc

.proc mult8
    jsr prepOperands8
    jsr multInt8
    jmp pushFromIntOp1
.endproc

.proc mult16
    jsr prepOperands16
    jsr multInt16
    jmp pushFromIntOp1
.endproc

.proc mult32
    jsr prepOperands32
    jsr multInt32
    jmp pushFromIntOp1And2
.endproc

.proc multReal
    jsr prepOperandsReal
    jsr FPMULT
    jmp pushRealStack
.endproc