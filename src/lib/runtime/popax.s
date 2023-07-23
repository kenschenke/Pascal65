.export popax
.importzp sp

.proc popax
    ldy #1
    lda (sp),y
    tax
    dey
    lda (sp),y
.endproc
