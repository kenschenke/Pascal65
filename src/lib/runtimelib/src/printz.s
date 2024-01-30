.include "cbm_kernal.inc"
.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp printz
jmp printlnz

; end of exports
.byte $00, $00, $00

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

.proc printz
    sta ptr1
    stx ptr1 + 1
    ldy #0
L1:
    lda (ptr1),y
    beq L2
    jsr CHROUT
    iny
    bne L1
L2:
    rts
.endproc

.proc printlnz
    jsr printz
    lda #13
    jmp CHROUT
.endproc
