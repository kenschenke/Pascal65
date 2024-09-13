.include "runtime.inc"
.include "types.inc"

.export spriteMoveRelCall

.import posx, posy, setSpriteXY

; Procedure SpriteMoveRel(number : Byte; xRel, yRel : Integer);
.proc spriteMoveRelCall
    lda #0                      ; Get the first parameter
    jsr rtLibLoadParam
    sta tmp1                    ; Store sprite number in tmp1
    asl a
    sta tmp2                    ; Store number*2 in tmp2
    lda #1                      ; Get the second parameter
    jsr rtLibLoadParam
    ldy tmp2
    cmp #00                     ; Is xRel negative?
    bpl :+                      ; Skip if not
    ldx #$ff                    ; Sign-extend it
:   clc
    adc posx,y
    sta posx,y
    txa
    adc posx+1,y
    sta posx+1,y
    lda #2                      ; Get the third parameter
    jsr rtLibLoadParam
    ldy tmp2
    cmp #$00                    ; Is yRel negative?
    bpl :+                      ; skip if not
    ldx #$ff                    ; Sign-extend it
:   clc
    adc posy,y
    sta posy,y
    txa
    adc posy+1,y
    sta posy+1,y

    ; lda #0                      ; Get the first parameter
    ; jsr rtLibLoadParam
    ; sta tmp1                    ; Store sprite number in tmp1
    ; asl a
    ; sta tmp2                    ; Store number*2 in tmp2
    ; lda #1                      ; Get the second parameter
    ; jsr rtLibLoadParam
    ; jsr rtPushEax
    ; lda #0
    ; sta sreg
    ; sta sreg+1
    ; ldy tmp2
    ; lda posx+1,y
    ; tax
    ; lda posx,y
    ; jsr rtPushEax
    ; lda #TYPE_INTEGER
    ; tax
    ; tay
    ; jsr rtAdd
    ; ldy tmp2
    ; sta posx,y
    ; txa
    ; sta posx+1,y
    ; lda #2                      ; Get the third parameter
    ; jsr rtLibLoadParam
    ; jsr rtPushEax
    ; lda #0
    ; sta sreg
    ; sta sreg+1
    ; ldy tmp2
    ; lda posy+1,y
    ; tax
    ; lda posy,y
    ; jsr rtPushEax
    ; lda #TYPE_INTEGER
    ; tax
    ; tay
    ; jsr rtAdd
    ; ldy tmp2
    ; sta posy,y
    ; txa
    ; sta posy+1,y


    ldx tmp1
    jmp setSpriteXY
.endproc
