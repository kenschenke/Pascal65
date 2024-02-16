; This routine divides two real numbers, <operand-1> and <operand-2>.
; Both operands are expected on the runtime stack with <operand-1>
; pushed first before <operand-2>.  The result is left at the top of the stack.

; Inputs:
;    A - data type of <operand-1>
;    X - data type of <operand-2>

.include "runtime.inc"
.include "types.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp divide

; end of exports
.byte $00, $00, $00

; imports

prepOperandsReal: jmp $0000
FPDIV: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

.proc divide
    ldy #TYPE_REAL
    jsr prepOperandsReal
    jsr FPDIV
    jmp rtPushReal
    rts
.endproc
