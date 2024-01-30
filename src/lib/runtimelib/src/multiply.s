; This routine multiplies two numbers, <operand-1> and <operand-2>.
; Both operands are expected on the runtime stack with <operand-1>
; pushed first before <operand-2>.  The result is left at the top of the stack.

; Inputs:
;    A - data type of <operand-1>
;    X - data type of <operand-2>
;    Y - data type of result

.include "types.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp multiply

; end of exports
.byte $00, $00, $00

; imports

prepOperands8: jmp $0000
prepOperands16: jmp $0000
prepOperands32: jmp $0000
prepOperandsReal: jmp $0000
multInt8: jmp $0000
multInt16: jmp $0000
multUint16: jmp $0000
multInt32: jmp $0000
multUint32: jmp $0000
FPMULT: jmp $0000
pushFromIntOp1: jmp $0000
pushFromIntOp1And2: jmp $0000
pushRealStack: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

.proc multiply
    cpy #TYPE_BYTE
    beq mult8
    cpy #TYPE_SHORTINT
    beq mult8
    cpy #TYPE_WORD
    beq multU16
    cpy #TYPE_INTEGER
    beq mult16
    cpy #TYPE_CARDINAL
    beq multU32
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

.proc multU16
    jsr prepOperands16
    jsr multUint16
    jmp pushFromIntOp1
.endproc

.proc mult32
    jsr prepOperands32
    jsr multInt32
    jmp pushFromIntOp1And2
.endproc

.proc multU32
    jsr prepOperands32
    jsr multUint32
    jmp pushFromIntOp1And2
.endproc

.proc multReal
    jsr prepOperandsReal
    jsr FPMULT
    jmp pushRealStack
.endproc
