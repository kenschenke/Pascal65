;
; drawtext.s
; Ken Schenke (kenschenke@gmail.com)
; 
; drawChar and drawText
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "runtime.inc"

.p4510

.export drawChar, drawCharRaw, drawText, drawTextRaw

.import calcScreen, toScreenCode, is80Cols, textColor

isRaw: .res 1

; Calculate the address in color RAM for Mega65
; Column in X, row in Y
; X and Y are preserved
; Address is left in ptr1/ptr2
.ifdef __MEGA65__
.proc calcColorAddr
    phx
    phy
    stx tmp1
    sty tmp2
    jsr is80Cols
    bne :+
    lda #40
    bne S3
:   lda #80
S3: sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ; 0x0FF80000 is base of color RAM
    lda #$f
    sta ptr2 + 1
    lda #$f8
    sta ptr2
    lda #0
    sta ptr1 + 1
    sta ptr1
LY: dec tmp2
    beq AX
    neg
    neg
    lda ptr1
    clc
    neg
    neg
    adc intOp32
    neg
    neg
    sta ptr1
    bra LY
AX: ldx tmp1
    dex
    stx intOp32
    neg
    neg
    lda ptr1
    clc
    neg
    neg
    adc intOp32
    neg
    neg
    sta ptr1
    ply
    plx
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
    plx
    phy
    phx
    jsr calcScreen          ; Get the address for the character
    neg
    neg
    sta ptr3
    lda #2                  ; Get the third parameter (character)
    jsr rtLibLoadParam
    ldx isRaw
    beq :+
    jsr toScreenCode
:   ldz #0
    nop
    sta (ptr3),z
    plx
    ply
    jsr calcColorAddr
    lda textColor
    ldz #0
    nop
    sta (ptr1),z
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
    plx
    phy
    phx
    jsr calcScreen          ; Get the address for the first character
    neg
    neg
    sta ptr3
    lda #2                  ; Get the third parameter (string)
    jsr rtLibLoadParam
    sta ptr1
    stx ptr1 + 1
    ldy #0
    lda (ptr1),y            ; Length of string
    bne :+
    pla
    pla
    rts
:   ldz #0
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
SC: nop
    sta (ptr3),z
    inz
    dex
    bpl LP
    pla
    plx
    ply
    pha
    jsr calcColorAddr
    lda textColor
    plx
    ldz #0
L2: nop
    sta (ptr1),z
    inz
    dex
    bpl L2
    rts
.endproc
