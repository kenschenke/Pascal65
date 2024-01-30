.include "float.inc"
.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp floatSqr

; end of exports
.byte $00, $00, $00

; imports

MOVIND: jmp $0000
FPMULT: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

.proc floatSqr
    lda #FPLSW
    sta FPBASE + FMPNT
    lda #FOPLSW
    sta FPBASE + TOPNT
    ldx #4
    jsr MOVIND
    jmp FPMULT
.endproc
