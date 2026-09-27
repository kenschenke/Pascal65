;
; palette.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Draw color palette and handle palette selection

.include "editor.inc"
.include "zeropage.inc"
.include "4510macros.inc"

PALETTE_ROW = 0
PALETTE_COL = 55
ROW_LENGTH = 20
SAMPLE_WIDTH = 8
SAMPLE_SPACING = 4
PALETTE_ROWS = 16

; Definitions for getPaletteColor
SELECT_COL1 = 53            ; Column to place cursor for column 1
SELECT_COL2 = 76            ; Column to place cursor for column 2
SELECT_CURSOR = '*'         ; Character to use for cursor
KEY_UPARROW = $91
KEY_DOWNARROW = $11
KEY_LEFTARROW = $9d
KEY_RIGHTARROW = $1d
KEY_ENTER = $0d

; Help Text
HELPTEXT_ROW = 17
HELPTEXT_COL = 9

.export drawColorPalette, getPaletteColor, initPalette, inPaletteMode
.export drawPaletteHelpText

.import getScreenRowPtr, getColorRowPtr, getKey, refreshScreen
.import petsciiToScreenCode, toVIC, fixAlphaCase, drawColorEditor, copyColorToTheme
.import getColorFromTheme, currentTheme

.bss

currentRow: .res 1
currentColor: .res 1
rowIndex: .res 1
selectedColor: .res 1
paletteIndex: .res 1
cursorRow: .res 1
cursorCol: .res 1
inPaletteMode: .res 1           ; Non-zero if a color is currently being selected

.data

paletteRow:
    .byte $a0, $a0, $a0, $a0, $a0, $a0, $a0, $a0
    .byte $20, $20, $20, $20
    .byte $a0, $a0, $a0, $a0, $a0, $a0, $a0, $a0

helpText1: .asciiz "* = Currently selected color"
helpText2: .asciiz "Use arrows to move selection"
helpText3: .asciiz "Return to use selected color"
helpText4: .asciiz "Press E to edit color"

.code

.proc initPalette
    lda #0
    sta inPaletteMode
    rts
.endproc

.proc drawColorPalette
    lda #PALETTE_ROW
    sta currentRow
    lda #0
    sta currentColor
    sta rowIndex

L1: lda currentRow
    jsr getScreenRowPtr
    sta ptr1
    stx ptr1+1
    ldx #0
    ldy #PALETTE_COL
:   lda paletteRow,x
    sta (ptr1),y
    inx
    iny
    cpx #ROW_LENGTH
    bne :-

    lda currentRow
    jsr getColorRowPtr
    stq ptr1

    ; Draw the color for the left column
    lda currentColor
    ldz #PALETTE_COL
    ldx #0
:   nop
    sta (ptr1),z
    inz
    inx
    cpx #SAMPLE_WIDTH
    bne :-

    ; Skip the space between the columns
    tza
    clc
    adc #SAMPLE_SPACING
    taz

    ; Draw the color for the right column
    lda currentColor
    clc
    adc #16
    jsr toVIC
    ldx #0
:   nop
    sta (ptr1),z
    inz
    inx
    cpx #SAMPLE_WIDTH
    bne :-

    inc currentRow
    inc currentColor
    inc rowIndex
    lda rowIndex
    cmp #16
    bne L1

    rts
.endproc

; Currently selected color passed in A.
; Palette index passed in X.
; New color returned in A.
.proc getPaletteColor
    sta selectedColor
    stx paletteIndex

    lda #1
    sta inPaletteMode

    jsr drawPaletteHelpText
    jsr renderCursor

    ; Loop, looking for keystrokes
L1: jsr getKey
    cmp #KEY_ENTER
    bne DN
    jsr clearCursor
    lda #0
    sta inPaletteMode
    lda selectedColor
    rts

DN: cmp #KEY_DOWNARROW
    bne UP
    jsr handleDownArrow
    bra L1

UP: cmp #KEY_UPARROW
    bne LF
    jsr handleUpArrow
    bra L1

LF: cmp #KEY_LEFTARROW
    bne RT
    jsr handleLeftArrow
    bra L1

RT: cmp #KEY_RIGHTARROW
    bne :+
    jsr handleRightArrow
    bra L1

:   jsr fixAlphaCase
    and #$7f            ; Convert to lower case
    cmp #'e'
    bne :+
    jsr clearHelpText
    lda selectedColor
    jsr drawColorEditor
    lda selectedColor
    ldx paletteIndex
    jsr copyColorToTheme
    jsr drawPaletteHelpText
    
:   bra L1
.endproc

; This routine handles the down arrow key.
.proc handleDownArrow
    lda selectedColor
    cmp #31
    bne :+
    rts
:   jsr clearCursor
    inc selectedColor
    ; lda selectedColor
    ; ldx paletteIndex
    ; jsr copyColorToTheme
    jsr updatePalette
    jsr renderCursor
    rts
.endproc

; This routine handles the left arrow key
.proc handleLeftArrow
    lda selectedColor
    cmp #16
    bcc :+
    jsr clearCursor
    lda selectedColor
    sec
    sbc #16
    sta selectedColor
    jsr updatePalette
    jsr renderCursor
:   rts
.endproc

; This routine handles the right arrow key
.proc handleRightArrow
    lda selectedColor
    cmp #16
    bcs :+
    jsr clearCursor
    lda selectedColor
    clc
    adc #16
    sta selectedColor
    jsr updatePalette
    jsr renderCursor
:   rts
.endproc

; This routine handles the up arrow key.
.proc handleUpArrow
    lda selectedColor
    beq :+
    jsr clearCursor
    dec selectedColor
    ; lda selectedColor
    ; ldx paletteIndex
    ; jsr copyColorToTheme
    jsr updatePalette
    jsr renderCursor
:   rts
.endproc

.proc clearHelpText
    lda #HELPTEXT_ROW
    jsr getScreenRowPtr
    jsr clearHelpTextRow

    lda #HELPTEXT_ROW+1
    jsr getScreenRowPtr
    jsr clearHelpTextRow

    lda #HELPTEXT_ROW+2
    jsr getScreenRowPtr
    jsr clearHelpTextRow

    lda #HELPTEXT_ROW+3
    jsr getScreenRowPtr
    jsr clearHelpTextRow

    lda #HELPTEXT_ROW+4
    jsr getScreenRowPtr
    jsr clearHelpTextRow

    lda #HELPTEXT_ROW+5
    jsr getScreenRowPtr
    jsr clearHelpTextRow

    rts
.endproc

; Screen RAM in A/X
.proc clearHelpTextRow
    sta ptr1
    stx ptr1+1
    lda #' '
    ldy #0
L1: sta (ptr1),y
    iny
    cpy #51
    bne L1
    rts
.endproc

.proc drawPaletteHelpText
    jsr clearHelpText

    lda #<helpText1
    ldx #>helpText2
    ldy #HELPTEXT_ROW
    jsr drawHelpTextRow

    lda #<helpText2
    ldx #>helpText2
    ldy #HELPTEXT_ROW+1
    jsr drawHelpTextRow

    lda #<helpText3
    ldx #>helpText3
    ldy #HELPTEXT_ROW+3
    jsr drawHelpTextRow

    lda #<helpText4
    ldx #>helpText4
    ldy #HELPTEXT_ROW+4
    jsr drawHelpTextRow

    rts
.endproc

; Pointer to null-terminated help text in A/X
; Row in Y
.proc drawHelpTextRow
    sta ptr1
    stx ptr1+1
    tya
    pha
    jsr getScreenRowPtr
    sta ptr2
    stx ptr2+1

    lda #0
    sta tmp1            ; help text index
    lda #HELPTEXT_COL
    sta tmp2            ; screen index

L1: ldy tmp1
    lda (ptr1),y
    beq L2
    jsr petsciiToScreenCode
    ldy tmp2
    sta (ptr2),y
    inc tmp1
    inc tmp2
    bne L1

L2: pla
    jsr getColorRowPtr
    stq ptr2
    lda #SYNTAXHL_FOREGROUND
    jsr getColorFromTheme
    jsr toVIC
    ldz #HELPTEXT_COL
L3: nop
    sta (ptr2),z
    inz
    cpz tmp2
    bne L3
    rts
.endproc

.proc renderCursor
    lda #SELECT_CURSOR
    jsr drawCursor
    rts
.endproc

.proc clearCursor
    lda #' '
    jsr drawCursor
    rts
.endproc

; This routine draws or clears the color selection cursor
; for the color in selectedColor.
; The character to draw is passed in A.
.proc drawCursor
    pha
    lda selectedColor
    cmp #37
    bcs CR
    cmp #32
    bcs CL
    cmp #16
    bcs RT
    clc
    adc #PALETTE_ROW
    ldy #SELECT_COL1
    bra GO

CR: sec
    sbc #18
    clc
    adc #PALETTE_ROW
    ldy #SELECT_COL2
    bra GO

CL: sec
    sbc #13
    clc
    adc #PALETTE_ROW
    ldy #SELECT_COL1
    bra GO

RT: sec
    sbc #16
    clc
    adc #PALETTE_ROW
    ldy #SELECT_COL2

GO: sta cursorRow
    sty cursorCol
    jsr getScreenRowPtr
    sta ptr1
    stx ptr1+1
    pla
    sta (ptr1),y

    lda cursorRow
    jsr getColorRowPtr
    stq ptr1
    lda #SYNTAXHL_FOREGROUND
    jsr getColorFromTheme
    jsr toVIC
    ldz cursorCol
    nop
    sta (ptr1),z

    rts
.endproc

; This routine updates the selected color in the
; palette currently being used to render the code sample.
.proc updatePalette
    lda selectedColor
    ldx paletteIndex
    jsr copyColorToTheme
    lda paletteIndex
    cmp #SYNTAXHL_BACKGROUND
    bne :+
    jsr calcContrastColor
:   jsr refreshScreen
    jsr drawPaletteHelpText
    rts
.endproc

; This routine is called when the background color is changed.
; It looks up the RGB values for the new background color and
; calculates a contrast color: either black or white to use
; for drawing the UI (boxes and text).
;
; The red, green, and blue colors are added together to see if
; the background color is closer to black or white.
.proc calcContrastColor
    jsr adjustForegroundColorIfNecessary
    lda #SYNTAXHL_BACKGROUND
    jsr getColorFromTheme
    sta $d020
    sta $d021
    tax
    lda $d100,x             ; red component
    sta tmp1
    lda $d200,x             ; green component
    clc
    adc tmp1
    sta tmp1
    lda $d300,x             ; blue component
    clc
    adc tmp1
    cmp #22                 ; is R+G+B >= 22?
    bcc L2
    lda #0
    bra L3
L2: lda #$0f
L3: pha
    lda #SYNTAXHL_FOREGROUND
    jsr getColorFromTheme
    tax
    pla
    sta $d100,x
    sta $d200,x
    sta $d300,x
    txa
    ldx #SYNTAXHL_FOREGROUND
    jsr copyColorToTheme
    rts
.endproc

; This routine looks to see if the foreground color is the same color number
; as the background color, and adjusts it if necessary to avoid conflicts.
.proc adjustForegroundColorIfNecessary
    lda #SYNTAXHL_FOREGROUND
    jsr getColorFromTheme
    sta tmp1
    lda #SYNTAXHL_BACKGROUND
    jsr getColorFromTheme
    cmp tmp1
    bne DN                  ; Branch if the colors are different
    ; The foreground color and the background color are the same, so we need to adjust the foreground color
    ; by finding a different color number that does not conflict with the background color.
    ldq currentTheme
    stq ptr1
    lda #0
    sta tmp1
L1: lda tmp1
    jsr isColorUsedInTheme
    bne L2
    inc tmp1
    lda tmp1
    cmp #31
    bne L1
L2: lda tmp1
    ldx #SYNTAXHL_FOREGROUND
    jsr copyColorToTheme
DN: rts
.endproc

; This routine looks at the color number in A (0-31) and sets the Z flag
; if the color is used in the current theme. This routine assumes ptr1
; points to the current theme.
;
; tmp4 is used
.proc isColorUsedInTheme
    sta tmp4
    ldx #0
    ldz #THEME::colors
L1: nop
    lda (ptr1),z
    cmp tmp4
    beq L2
    inz
    inz
    inz
    inz
    inx
    cpx #10
    bne L1
    lda #1              ; Turn off the Z flag
L2: rts
.endproc
