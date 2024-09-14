.include "runtime.inc"
.include "c64.inc"

.export spriteSizeCall

.import SPR_MASKS

.proc spriteSizeCall
    lda #0
    jsr rtLibLoadParam                  ; Get the first parameter
    sta tmp1
    ; Set up masks for setting and clearing the bits
    tax
    lda SPR_MASKS,x
    sta tmp2
    eor #$ff
    sta tmp3
    lda #1
    jsr rtLibLoadParam                  ; Get the second parameter
    cmp #0
    beq :+
    ; Double-size horizontal
    lda tmp2
    ora VIC_SPR_EXP_X
    sta VIC_SPR_EXP_X
    jmp L1
:   ; Normal size horizontal
    lda tmp3
    and VIC_SPR_EXP_X
    sta VIC_SPR_EXP_X
L1: lda #2                              ; Get the third parameter
    jsr rtLibLoadParam
    cmp #0
    beq :+
    ; Double-size vertical
    lda tmp2
    ora VIC_SPR_EXP_Y
    sta VIC_SPR_EXP_Y
    rts
:   ; Normal size vertical
    lda tmp3
    and VIC_SPR_EXP_Y
    sta VIC_SPR_EXP_Y
    rts
.endproc
