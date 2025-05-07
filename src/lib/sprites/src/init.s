.include "c64.inc"

.export initSpriteLibrary

.import initSpriteBss

initSpriteLibrary:
    jsr initSpriteBss

    lda #0
    sta VIC_SPR_ENA         ; Disable all sprites
    rts
