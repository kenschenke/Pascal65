;
; Ullrich von Bassewitz, 25.10.2000
;
; CC65 runtime: Increment the stackpointer by 4
;

.include "runtime.inc"

.export popax, popa

.proc popax
    ldy #1
    lda (sp),y
    tax
    dey
    lda (sp),y
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
