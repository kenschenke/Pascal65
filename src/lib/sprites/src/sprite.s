.include "runtime.inc"
.include "c64.inc"

.export spriteCall

.import SPR_MASKS

; Procedure Sprite(number, color : Byte; enabled, isMultiColor : Boolean);
.proc spriteCall
    lda #0                      ; Get the first parameter
    jsr rtLibLoadParam
    sta tmp1
    tax                         ; Put the sprite number in X
    lda SPR_MASKS,x             ; Load the mask for the number
    sta tmp2
    eor #$ff
    sta tmp3
    lda #1                      ; Get the second parameter
    jsr rtLibLoadParam
    ldx tmp1
    sta VIC_SPR0_COLOR,x
    lda #2                      ; Get the third parameter
    jsr rtLibLoadParam
    cmp #0
    bne EN                      ; Branch is enabled is True
    lda tmp3
    and VIC_SPR_ENA
    sta VIC_SPR_ENA
    jmp MC
EN: lda tmp2
    ora VIC_SPR_ENA             ; Set the enable bit for this sprite
    sta VIC_SPR_ENA
MC: lda #3                      ; Get the fourth parameter
    jsr rtLibLoadParam
    cmp #0
    bne :+
    lda tmp3
    and VIC_SPR_MCOLOR
    sta VIC_SPR_MCOLOR
    rts
:   lda tmp2
    ora VIC_SPR_MCOLOR
    sta VIC_SPR_MCOLOR
    rts
.endproc
