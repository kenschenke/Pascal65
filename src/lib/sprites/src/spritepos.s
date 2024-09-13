.include "runtime.inc"

.export spritePosCall

.import posx, posy, setSpriteXY

; Procedure SpritePos(number : Byte; x, y : Integer);
.proc spritePosCall
    lda #0                      ; Get the first parameter
    jsr rtLibLoadParam
    sta tmp1                    ; Store sprite number in tmp1
    asl a
    sta tmp2                    ; Store number*2 in tmp2
    lda #1                      ; Get the second parameter
    jsr rtLibLoadParam
    ldy tmp2
    sta posx,y
    txa
    sta posx+1,y
    lda #2                      ; Get the third parameter
    jsr rtLibLoadParam
    ldy tmp2
    sta posy,y
    lda #0
    sta posy+1,y
    ldx tmp1
    jmp setSpriteXY
.endproc
