.include "float.inc"
.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp floatAbs

; end of exports
.byte $00, $00, $00

; imports

floatNeg: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

.proc floatAbs
    lda FPBASE + FPMSW
    and #$80                ; Check for high bit in MSB
    beq L1                  ; If not set, jump ahead
    jmp floatNeg
L1:
    rts
.endproc
