.include "cbm_kernal.inc"

.ifdef RUNTIME
.include "runtime.inc"
.else
.importzp ptr1
.endif

.export printz, printlnz

.proc printz
    sta ptr1
    stx ptr1 + 1
    ldy #0
L1:
    lda (ptr1),y
    beq L2
    jsr CHROUT
    iny
    jmp L1
L2:
    rts
.endproc

.proc printlnz
    jsr printz
    lda #13
    jmp CHROUT
.endproc
