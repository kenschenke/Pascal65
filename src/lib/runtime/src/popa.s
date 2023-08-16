.export popa
.importzp sp

.proc popa
    ldy #0
    lda (sp),y
    inc sp
    beq @L1
    rts
@L1:
    inc sp+1
    rts
.endproc
