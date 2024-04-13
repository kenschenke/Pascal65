; ClearScreen library function

.include "runtime.inc"

.export drawChar, drawCharRaw, drawText, drawTextRaw

.import calcScreen, toScreenCode, is80Cols
.import lfill, lpoke, textColor
.ifdef __MEGA65__
.import dma_addr, dma_count, dma_value
.endif

isRaw: .res 1

; Calculate the address in color RAM for Mega65
; Column in X, row in Y
; X and Y are preserved
; Address is left in dma_addr
.ifdef __MEGA65__
.proc calcColorAddr
    stx tmp1
    sty tmp2
    jsr is80Cols
    bne :+
    lda #40
    bne S3
:   lda #80
S3: sta tmp3
    ; 0x0FF80000 is base of color RAM
    lda #$f
    sta dma_addr + 3
    lda #$f8
    sta dma_addr + 2
    lda #0
    sta dma_addr + 1
    sta dma_addr
    ldy tmp2
LY: dey
    beq AX
    lda dma_addr
    clc
    adc tmp3
    sta dma_addr
    lda dma_addr + 1
    adc #0
    sta dma_addr + 1
    jmp LY
AX: ldx tmp1
    dex
    txa
    clc
    adc dma_addr
    sta dma_addr
    lda dma_addr + 1
    adc #0
    sta dma_addr + 1
    ldx tmp1
    ldy tmp2
    rts
.endproc
.endif

; This routine draws a character to the screen

.proc drawChar
    lda #1
    sta isRaw
    bne drawCharX
.endproc

.proc drawCharRaw
    lda #0
    sta isRaw
    ; Fall through to drawCharX
.endproc

; A : 0 if character is raw screen code
;   : non-0 if character is PETSCII
.proc drawCharX
    lda #0                  ; Get the first parameter (column)
    jsr rtLibLoadParam
    pha
    lda #1                  ; Get the second parameter (row)
    jsr rtLibLoadParam
    tay
    pla
    tax
.ifdef __MEGA65__
    jsr calcColorAddr
.endif
    jsr calcScreen          ; Get the address for the character
    sta ptr2
    stx ptr2 + 1
    lda #2                  ; Get the third parameter (character)
    jsr rtLibLoadParam
    ldx isRaw
    beq :+
    jsr toScreenCode
:   ldy #0
    sta (ptr2),y
.ifdef __MEGA65__
    lda textColor
    sta dma_value
    jsr lpoke
.endif
    rts
.endproc

.proc drawText
    lda #1
    sta isRaw
    bne drawTextX
.endproc

.proc drawTextRaw
    lda #0
    sta isRaw
    ; Fall through to drawTextX
.endproc

; This routine draws a string to the screen

; A : 0 if character is raw screen code
;   : non-0 if character is PETSCII
.proc drawTextX
    lda #0                  ; Get the first parameter (column)
    jsr rtLibLoadParam
    pha
    lda #1                  ; Get the second parameter (row)
    jsr rtLibLoadParam
    tay
    pla
    tax
.ifdef __MEGA65__
    jsr calcColorAddr
.endif
    jsr calcScreen          ; Get the address for the first character
    sta ptr2
    stx ptr2 + 1
    lda #2                  ; Get the third parameter (string)
    jsr rtLibLoadParam
    sta ptr1
    stx ptr1 + 1
    ldy #0
    lda (ptr1),y            ; Length of string
    beq DN
    pha
    tax
    dex
LP: iny
    lda isRaw
    bne NS
    lda (ptr1),y
    bne SC
NS: lda (ptr1),y
    jsr toScreenCode
SC: dey
    sta (ptr2),y
    iny
    dex
    bpl LP
DN: pla
    sta dma_count
.ifdef __MEGA65__
    lda textColor
    sta dma_value
    lda #0
    sta dma_count + 1
    jsr lfill
.endif
    rts
.endproc
