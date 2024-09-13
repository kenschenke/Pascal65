.include "runtime.inc"
.include "types.inc"

.export spriteMoveRelCall

.import posx, posy, setSpriteXY

; Procedure SpriteMoveRel(number : Byte; xRel : Integer; yRel : Byte);
.proc spriteMoveRelCall
    lda #0                      ; Get the first parameter
    jsr rtLibLoadParam
    sta tmp1                    ; Store sprite number in tmp1
    asl a
    sta tmp2                    ; Store number*2 in tmp2
    lda #1                      ; Get the second parameter
    jsr rtLibLoadParam
    ldy tmp2
    clc
    adc posx,y
    sta posx,y
    txa
    adc posx+1,y
    sta posx+1,y
    lda #2                      ; Get the third parameter
    jsr rtLibLoadParam
    ldx tmp1
    clc
    adc posy,x
    sta posy,x
    jmp setSpriteXY
.endproc
