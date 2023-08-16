.include "runtime.inc"

.export pusheax
.import decsp4

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
