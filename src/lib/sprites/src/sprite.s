.include "runtime.inc"
.include "c64.inc"

.export spriteCall

.import SPR_MASKS

; Procedure Sprite(number : Byte; enabled : Boolean);
.proc spriteCall
    lda #0                      ; Get the first parameter
    jsr rtLibLoadParam
    tax                         ; Put the sprite number in X
    lda SPR_MASKS,x             ; Load the mask for the number
    pha
    lda #1                      ; Get the second parameter
    jsr rtLibLoadParam
    cmp #0
    bne EN                      ; Branch is enabled is True
    pla
    eor #$ff                    ; Clear the enable bit for this sprite
    and VIC_SPR_ENA
    sta VIC_SPR_ENA
    rts
EN: pla
    ora VIC_SPR_ENA             ; Set the enable bit for this sprite
    sta VIC_SPR_ENA
    rts
.endproc
