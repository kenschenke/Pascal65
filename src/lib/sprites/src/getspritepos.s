.include "runtime.inc"
.include "c64.inc"

.export getSpritePosCall

.import SPR_MASKS

; Procedure GetSpritePos(number : Byte; Var x : Word; Var y : Byte);
.proc getSpritePosCall
    lda #0                      ; Get the first parameter
    jsr rtLibLoadParam
    sta tmp1                    ; Store sprite number in tmp1
    asl a                       ; Multiply sprite number by two
    sta tmp2
    lda #1
    jsr rtLibLoadParam          ; Get the second param (address of x)
    sta ptr1
    stx ptr1+1
    ldx #0
    ldy tmp1
    lda SPR_MASKS,y
    and VIC_SPR_HI_X
    beq :+
    ldx #1
:   ldy tmp2
    lda VIC_SPR0_X,y
    ldy #0
    sta (ptr1),y
    iny
    txa
    sta (ptr1),y
    lda #2                      ; Get the third param (address of y)
    jsr rtLibLoadParam
    sta ptr1
    stx ptr1+1
    ldx tmp2
    lda VIC_SPR0_Y,x
    ldy #0
    sta (ptr1),y
    rts
.endproc
