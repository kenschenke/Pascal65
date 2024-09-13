.include "runtime.inc"
.include "c64.inc"

.export spriteMoveCall

.import posx, posy, x0, x1, y0, y1, hastarget, speed, initLine
.import SPR_MASKS

; Procedure SpriteMove(number : Byte; x0 : Integer; y0 : Byte;
;    x1 : Integer; y1, speed : Byte);
.proc spriteMoveCall
    lda #0                      ; Get the first parameter
    jsr rtLibLoadParam
    sta tmp1                    ; Store sprite number in tmp1
    asl a
    sta tmp2                    ; Store number*2 in tmp2
    lda #1                      ; Get the second parameter
    jsr rtLibLoadParam
    ldy tmp2
    sta posx,y
    sta x0,y
    txa
    lda #0
    sta posx+1,y
    sta x0+1,y
    lda #2                      ; Get the third parameter
    jsr rtLibLoadParam
    ldx tmp1
    sta posy,x
    sta y0,x
    lda #3                      ; Get the fourth parameter
    jsr rtLibLoadParam
    ldy tmp2
    sta x1,y
    txa
    ; lda #0
    sta x1+1,y
    lda #4                      ; Get the fifth parameter
    jsr rtLibLoadParam
    ldx tmp1
    sta y1,x
    lda #5                      ; Get the sixth parameter
    jsr rtLibLoadParam
    ldx tmp1
    sta speed,x
    ; Enable targeting for the sprite
    lda SPR_MASKS,x
    ora hastarget
    sta hastarget
    ; brk
    jsr initLine                ; Calculate the line slope
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; lda speed+1
    ; ldx hastarget
    ; lda dy,y
    ; ldx dy+1,y
    ; lda err,y
    ; ldx err+1,y
    ; brk
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Enable sprite
    lda SPR_MASKS,x
    ora VIC_SPR_ENA
    sta VIC_SPR_ENA
    rts
.endproc
