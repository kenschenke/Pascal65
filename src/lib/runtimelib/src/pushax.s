.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp pushax
jmp pusha

; end of exports
.byte $00, $00, $00

; imports

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

.proc pushax
    pha
    lda sp
    sec
    sbc #2
    sta sp
    bcs L1
    dec sp + 1
L1:
    ldy #1
    txa
    sta (sp),y
    pla
    dey
    sta (sp),y
    rts
.endproc

.proc pusha
    ldy sp
    beq L1
    dec sp
    ldy #0
    sta (sp),y
    rts
L1:
    dec sp + 1
    dec sp
    sta (sp),y
    rts
.endproc
