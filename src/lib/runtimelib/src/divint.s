; This routine divides two integers, <operand-1> divided by <operand-2>.
; Both operands are expected on the runtime stack with <operand-1>
; pushed first before <operand-2>.  The result is left at the top of the stack.

; Inputs:
;    A - data type of <operand-1>
;    X - data type of <operand-2>
;    Y - data type of result

.include "runtime.inc"
.include "types.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp divint

; end of exports
.byte $00, $00, $00

; imports

prepOperands8: jmp $0000
prepOperands16: jmp $0000
prepOperands32: jmp $0000
prepOperandsReal: jmp $0000
divInt8: jmp $0000
divInt16: jmp $0000
divInt32: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

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

