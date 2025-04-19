.include "runtime.inc"
.include "c64.inc"

.export spritePosCall

.import SPR_MASKS

; Procedure SpritePos(number : Byte; x : Integer; y : Byte);
.proc spritePosCall
    lda #0                      ; Get the first parameter
    jsr rtLibLoadParam
    sta tmp1                    ; Store sprite number in tmp1
    asl a                       ; Multiply sprite number by two
    sta tmp2
    lda #2                      ; Get the third parameter
    jsr rtLibLoadParam
    ldx tmp2
    sta VIC_SPR0_Y,x
    lda #1                      ; Get the second parameter
    jsr rtLibLoadParam
    ldy tmp2
    sta VIC_SPR0_X,y
    ldy tmp1
    txa
    bne :+
    lda SPR_MASKS,y
    eor #$ff
    and VIC_SPR_HI_X
    sta VIC_SPR_HI_X
    rts
:   lda VIC_SPR_HI_X
    ora SPR_MASKS,y
    sta VIC_SPR_HI_X
    rts
.endproc
