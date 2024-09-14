.include "runtime.inc"
.include "c64.inc"

.export spriteMultiColorCall

.import SPR_MASKS

.proc spriteMultiColorCall
    lda #0
    jsr rtLibLoadParam                  ; Get the first parameter
    sta tmp1
    lda #1
    jsr rtLibLoadParam                  ; Get the second parameter
    ldx tmp1
    cmp #0
    beq :+
    ; Turn on multicolor for this sprite
    lda SPR_MASKS,x
    ora VIC_SPR_MCOLOR
    sta VIC_SPR_MCOLOR
    rts
    ; Turn off multicolor for this sprite
:   lda SPR_MASKS,x
    eor #$ff
    and VIC_SPR_MCOLOR
    sta VIC_SPR_MCOLOR
    rts
.endproc
