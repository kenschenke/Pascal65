.include "runtime.inc"
.include "c64.inc"

.export spriteMultiColorsCall

.proc spriteMultiColorsCall
    lda #0
    jsr rtLibLoadParam                  ; Get the first parameter
    sta VIC_SPR_MCOLOR0
    lda #1                              ; Get the second parameter
    jsr rtLibLoadParam
    sta VIC_SPR_MCOLOR1
    rts
.endproc
