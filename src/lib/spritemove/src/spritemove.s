.include "runtime.inc"
.include "c64.inc"

.export spriteMoveCall

.import posx, posy, x0, x1, y0, y1, hastarget, speed, initLine
.import SPR_MASKS

; Procedure SpriteMove(number : Byte; x0 : Integer; y0 : Byte;
;    x1 : Integer; y1, speed : Byte; stopAtTarget : Boolean);
.proc spriteMoveCall
    lda #0                      ; Get the sprite number parameter
    jsr rtLibLoadParam
    sta tmp1                    ; Store sprite number in tmp1
    asl a
    sta tmp2                    ; Store number*2 in tmp2
    lda #1                      ; Get the x0 parameter
    jsr rtLibLoadParam
    ldy tmp2
    sta posx,y
    sta x0,y
    txa
    sta posx+1,y
    sta x0+1,y
    lda #2                      ; Get the y0 parameter
    jsr rtLibLoadParam
    ldx tmp1
    sta posy,x
    sta y0,x
    lda #3                      ; Get the x1 parameter
    jsr rtLibLoadParam
    ldy tmp2
    sta x1,y
    txa
    sta x1+1,y
    lda #4                      ; Get the y1 parameter
    jsr rtLibLoadParam
    ldx tmp1
    sta y1,x
    lda #5                      ; Get the speed parameter
    jsr rtLibLoadParam
    ldx tmp1
    sta speed,x
    lda #6                      ; Get the target (t/f) parameter
    jsr rtLibLoadParam
    ldx tmp1
    cmp #0
    beq :+
    ; Enable targeting for the sprite
    lda SPR_MASKS,x
    ora hastarget
    sta hastarget
    bne IL
:   ; Disable targeting for the sprite
    lda SPR_MASKS,x
    eor #$ff
    and hastarget
    sta hastarget
IL: jsr initLine                ; Calculate the line slope
    ; Enable sprite
    lda SPR_MASKS,x
    ora VIC_SPR_ENA
    sta VIC_SPR_ENA
    rts
.endproc
