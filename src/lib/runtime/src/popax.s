.include "runtime.inc"

.export popax

.proc popax
    ldy #1
    lda (sp),y
    tax
    dey
    lda (sp),y
.endproc

.proc incsp2
    inc sp
    beq L1
    inc sp
    beq L2
    rts
L1:
    inc sp
L2:
    inc sp + 1
    rts
.endproc
