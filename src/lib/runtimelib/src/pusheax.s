.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp pusheax

; end of exports
.byte $00, $00, $00

; imports

decsp4: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

.proc pusheax
    pha                     ; decsp will destroy A (but not X)
    jsr     decsp4
    ldy     #3
    lda     sreg+1
    sta     (sp),y
    dey
    lda     sreg
    sta     (sp),y
    dey
    txa
    sta     (sp),y
    pla
    dey
    sta     (sp),y
    rts
.endproc
