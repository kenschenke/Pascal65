.include "runtime.inc"
.include "c64.inc"

.export spriteColorCall

.import posx, posy, setSpriteXY

; Procedure SpriteColor(number, color : Byte);
.proc spriteColorCall
    lda #0                      ; Get the first parameter
    jsr rtLibLoadParam
    sta tmp1                    ; Store sprite number in tmp1
    lda #1                      ; Get the second parameter
    jsr rtLibLoadParam
    ldx tmp1
    sta VIC_SPR0_COLOR,x
    rts
.endproc
