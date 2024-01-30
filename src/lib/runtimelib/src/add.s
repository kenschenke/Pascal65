; This routine adds two numbers, <operand-1> and <operand-2>.
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

jmp add

; end of exports
.byte $00, $00, $00

; imports

prepOperands8: jmp $0000
prepOperands16: jmp $0000
prepOperands32: jmp $0000
prepOperandsReal: jmp $0000
addInt8: jmp $0000
addInt16: jmp $0000
addInt32: jmp $0000
FPADD: jmp $0000
pushFromIntOp1: jmp $0000
pushFromIntOp1And2: jmp $0000
pushRealStack: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

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
