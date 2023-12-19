; This routine adds two numbers, <operand-1> and <operand-2>.
; Both operands are expected on the runtime stack with <operand-1>
; pushed first before <operand-2>.  The result is left at the top of the stack.

; Inputs:
;    A - data type of <operand-1>
;    X - data type of <operand-2>
;    Y - data type of result

.include "types.inc"

.export add

.import prepOperands8, prepOperands16, prepOperands32, prepOperandsReal
.import addInt8, addInt16, addInt32, FPADD
.import pushFromIntOp1, pushFromIntOp1And2, pushRealStack

.proc add
    cpy #TYPE_BYTE
    beq add8
    cpy #TYPE_SHORTINT
    beq add8
    cpy #TYPE_WORD
    beq add16
    cpy #TYPE_INTEGER
    beq add16
    cpy #TYPE_CARDINAL
    beq add32
    cpy #TYPE_LONGINT
    beq add32
    cpy #TYPE_REAL
    beq addReal
    rts
.endproc

.proc add8
    jsr prepOperands8
    jsr addInt8
    jmp pushFromIntOp1
.endproc

.proc add16
    jsr prepOperands16
    jsr addInt16
    jmp pushFromIntOp1
.endproc

.proc add32
    jsr prepOperands32
    jsr addInt32
    jmp pushFromIntOp1And2
.endproc

.proc addReal
    jsr prepOperandsReal
    jsr FPADD
    jmp pushRealStack
.endproc
