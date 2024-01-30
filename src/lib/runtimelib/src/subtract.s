; This routine subtracts two numbers, <operand-2> from <operand-1>.
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

jmp subtract

; end of exports
.byte $00, $00, $00

; imports

prepOperands8: jmp $0000
prepOperands16: jmp $0000
prepOperands32: jmp $0000
prepOperandsReal: jmp $0000
subInt8: jmp $0000
subInt16: jmp $0000
subInt32: jmp $0000
FPSUB: jmp $0000
pushFromIntOp1: jmp $0000
pushFromIntOp1And2: jmp $0000
pushRealStack: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

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
    jmp pushFromIntOp1
.endproc

.proc sub16
    jsr prepOperands16
    jsr subInt16
    jmp pushFromIntOp1
.endproc

.proc sub32
    jsr prepOperands32
    jsr subInt32
    jmp pushFromIntOp1And2
.endproc

.proc subReal
    jsr prepOperandsReal
    jsr FPSUB
    jmp pushRealStack
.endproc
