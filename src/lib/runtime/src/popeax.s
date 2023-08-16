.include "runtime.inc"

.export popeax
.import incsp4

.proc popeax
    ldy #3
    lda (sp),y
    sta sreg + 1
    dey
    lda (sp),y
    sta sreg
    dey
    lda (sp),y
    tax
    dey
    lda (sp),y
    jmp incsp4
.endproc
