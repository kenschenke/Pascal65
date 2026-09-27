;
; editcolor.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Edit color RGB values

.include "editor.inc"
.include "zeropage.inc"
.include "4510macros.inc"

EDITCOLOR_ROW = 17
EDITCOLOR_LABEL_COL = 8
EDITCOLOR_BAR_COL = 15
EDITCOLOR_BAR_WIDTH = 16    ; Not including '[' and ']'
EDITCOLOR_BAR_LEFT = '['
EDITCOLOR_BAR_RIGHT = ']'
EDITCOLOR_BAR_FILL = '-'
EDITCOLOR_BAR_CURSOR = '*'

KEY_LEFTARROW = $9d
KEY_RIGHTARROW = $1d
KEY_RETURN = $0d

.export drawColorEditor

.import petsciiToScreenCode, getScreenRowPtr, getColorRowPtr
.import  getKey, fixAlphaCase, getColorFromTheme, toVIC

.bss

currentRow: .res 1
selectedColor: .res 1           ; color number

.data

editTextR: .asciiz "Red"
editTextG: .asciiz "Green"
editTextB: .asciiz "Blue"
editHelpText1: .asciiz "Type 'R', 'G', or 'B' then arrow keys to adjust"
editHelpText2: .asciiz "Press Return to accept."

.code

.proc drawColorEditor
    sta selectedColor

    lda #<editTextR
    ldx #>editTextR
    ldy #EDITCOLOR_ROW
    jsr drawEditColorBar

    lda #<editTextG
    ldx #>editTextG
    ldy #EDITCOLOR_ROW+2
    jsr drawEditColorBar

    lda #<editTextB
    ldx #>editTextB
    ldy #EDITCOLOR_ROW+4
    jsr drawEditColorBar

    lda #<editHelpText1
    ldx #>editHelpText1
    ldy #EDITCOLOR_ROW+6
    jsr drawEditHelpText

    lda #<editHelpText2
    ldx #>editHelpText2
    ldy #EDITCOLOR_ROW+7
    jsr drawEditHelpText

    ; Plot the current color positions
    ldx selectedColor
    lda $d100,x
    ldy #EDITCOLOR_ROW
    jsr plotColorPosition

    ldx selectedColor
    lda $d200,x
    ldy #EDITCOLOR_ROW+2
    jsr plotColorPosition

    ldx selectedColor
    lda $d300,x
    ldy #EDITCOLOR_ROW+4
    jsr plotColorPosition

    ; Ptr1 is pointer to color bank
    ; R=$d100, G=$d200, B=$d300
    lda #0
    sta ptr1
    sta ptr1+1

L1: jsr getKey
    cmp #KEY_LEFTARROW
    bne :+
    lda ptr1+1
    beq L1
    ldy selectedColor
    lda (ptr1),y
    sta tmp1
    beq L1
    sec
    sbc #1
    sta (ptr1),y
    sta tmp2
    jsr moveColorPosition
    bra L1

:   cmp #KEY_RIGHTARROW
    bne :+
    lda ptr1+1
    beq L1
    ldy selectedColor
    lda (ptr1),y
    sta tmp1
    cmp #$0f
    beq L1
    clc
    adc #1
    sta (ptr1),y
    sta tmp2
    jsr moveColorPosition
    bra L1

:   cmp #KEY_RETURN
    bne :+
    jsr clearHelpText
    rts

:   jsr fixAlphaCase
    and #$7f                ; Force to lowercase
    cmp #'r'
    bne :+
    lda #$d1
    sta ptr1+1
    lda #EDITCOLOR_ROW
    jsr getScreenRowPtr
    sta ptr2
    stx ptr2+1
    bra L1

:   cmp #'g'
    bne :+
    lda #$d2
    sta ptr1+1
    lda #EDITCOLOR_ROW+2
    jsr getScreenRowPtr
    sta ptr2
    stx ptr2+1
    bra L1

:   cmp #'b'
    bne L1
    lda #$d3
    sta ptr1+1
    lda #EDITCOLOR_ROW+4
    jsr getScreenRowPtr
    sta ptr2
    stx ptr2+1
    jmp L1
.endproc

.proc drawEditColorBar
    pha
    phx
    sty currentRow
    tya
    jsr getScreenRowPtr
    sta ptr2
    stx ptr2+1
    pla
    sta ptr1+1
    pla
    sta ptr1

    lda #0
    sta tmp1
    lda #EDITCOLOR_LABEL_COL
    sta tmp2
:   ldy tmp1
    lda (ptr1),y
    beq :+
    jsr petsciiToScreenCode
    ldy tmp2
    sta (ptr2),y
    inc tmp1
    inc tmp2
    bne :-

:   lda #EDITCOLOR_BAR_LEFT
    jsr petsciiToScreenCode
    ldy #EDITCOLOR_BAR_COL
    sta (ptr2),y
    iny
    lda #EDITCOLOR_BAR_FILL
    jsr petsciiToScreenCode
    ldx #0
:   sta (ptr2),y
    iny
    inx
    cpx #EDITCOLOR_BAR_WIDTH
    bne :-
    lda #EDITCOLOR_BAR_RIGHT
    jsr petsciiToScreenCode
    sta (ptr2),y

    ; Set it to the foreground color
    lda currentRow
    jsr getColorRowPtr
    stq ptr1
    lda #SYNTAXHL_FOREGROUND
    jsr getColorFromTheme
    jsr toVIC
    ldz #EDITCOLOR_LABEL_COL
:   nop
    sta (ptr1),z
    inz
    cpz #EDITCOLOR_BAR_WIDTH+EDITCOLOR_BAR_COL+7
    bne :-

    rts
.endproc

.proc clearHelpText
    lda #EDITCOLOR_ROW+6
    jsr clearHelpTextRow

    lda #EDITCOLOR_ROW+7
    jsr clearHelpTextRow

    rts
.endproc

.proc clearHelpTextRow
    jsr getScreenRowPtr
    sta ptr1
    stx ptr1+1

    ldy #EDITCOLOR_LABEL_COL
    ldx #0
    lda #' '
:   sta (ptr1),y
    iny
    inx
    cpx #50
    bne :-

    rts
.endproc

.proc drawEditHelpText
    pha
    phx
    tya
    sta currentRow
    jsr getScreenRowPtr
    sta ptr2
    stx ptr2+1
    pla
    sta ptr1+1
    pla
    sta ptr1

    lda #0
    sta tmp1
    lda #EDITCOLOR_LABEL_COL
    sta tmp2

:   ldy tmp1
    lda (ptr1),y
    beq :+
    jsr petsciiToScreenCode
    ldy tmp2
    sta (ptr2),y
    inc tmp1
    inc tmp2
    bne :-

:   lda tmp1
    pha
    lda currentRow
    jsr getColorRowPtr
    stq ptr1

    pla
    sta tmp1
    lda #SYNTAXHL_FOREGROUND
    jsr getColorFromTheme
    jsr toVIC
    ldz #EDITCOLOR_LABEL_COL
:   nop
    sta (ptr1),z
    inz
    dec tmp1
    bne :-

    rts
.endproc

; RGB value in A $00-$0f
; Row in Y
.proc plotColorPosition
    pha
    tya
    jsr getScreenRowPtr
    sta ptr1
    stx ptr1+1

    pla
    clc
    adc #EDITCOLOR_BAR_COL
    clc
    adc #1
    tay
    lda #EDITCOLOR_BAR_CURSOR
    sta (ptr1),y

    rts
.endproc

; This routine moves the cursor on the color bar.
; Screen RAM is in ptr2
; tmp1=old position
; tmp2=new position
.proc moveColorPosition
    lda tmp1
    clc
    adc #EDITCOLOR_BAR_COL
    clc
    adc #1
    tay
    lda #'-'
    sta (ptr2),y

    lda tmp2
    clc
    adc #EDITCOLOR_BAR_COL
    clc
    adc #1
    tay
    lda #EDITCOLOR_BAR_CURSOR
    sta (ptr2),y

    rts
.endproc
