.include "c64.inc"

.export cleanupSpriteLibrary

.proc cleanupSpriteLibrary
    ; Turn off all sprites
    lda #0
    sta VIC_SPR_ENA
    rts
.endproc
