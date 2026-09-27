;
; themelist.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Display and manage the list of themes

.include "c64.inc"
.include "asmlib.inc"
.include "editor.inc"
.include "zeropage.inc"
.include "4510macros.inc"

LIST_COL = 55
LIST_ROW = 0
LIST_ROWS = 12              ; Does not include borders
LIST_HEIGHT = LIST_ROWS+4   ; Includes borders
LIST_WIDTH = 20             ; Includes borders
HELPTEXT_ROW = 17
HELPTEXT_COL = 55

; Screen codes for the drawing characters
CH_UPPERLEFT = $70
CH_UPPERRIGHT = $6e
CH_LOWERLEFT = $6d
CH_LOWERRIGHT = $7d
CH_VERTBAR = $5d
CH_HORIZBAR = $40
CH_LEFTSPLIT = $6b
CH_RIGHTSPLIT = $73

; Keys
KEY_UPARROW = $91
KEY_DOWNARROW = $11
KEY_ENTER = $0d

.export initThemeList, getTheme, themeList, selectedThemeNum, freeThemeList
.export numThemes, inThemeList, copyColorToTheme, getColorFromTheme
.export currentTheme, copyColorsFromTheme, setCurrentTheme

.import petsciiToScreenCode, getScreenRowPtr, getColorRowPtr
.import getKey, refreshScreen, readThemeFile, toVIC

.bss

themeList: .res 4
currentTheme: .res 4
themePtr: .res 4
lastThemeNode: .res 4
intBuf: .res 5
currentScreenRow: .res 1
currentThemeNum: .res 1
selectedThemeNum: .res 1
topRow: .res 1
selectMask: .res 1
numThemes: .res 1
inThemeList: .res 1

.data

listTitle: .asciiz "Themes"
helpText1: .asciiz "Use Arrows and Return"
helpText2: .asciiz "to select theme"

.code

.proc initThemeList
    ; Read the themes file
    jsr readThemeFile

    ; Set the currentTheme variable, based on the selectedTheme value
    jsr setCurrentTheme

    ; Copy colors from the current theme to the VIC registers
    jsr copyColorsFromTheme

    rts
.endproc

.proc freeThemeList
    ldq themeList
    stq themePtr

    ; Loop through the themes
L1: jsr isQZero
    beq L2

    jsr heapFree

    ldq themePtr
    stq ptr1

    ldz #THEME::next
    neg
    neg
    nop
    lda (ptr1),z
    stq themePtr
    bra L1

L2: rts
.endproc

.proc clearList
    lda #LIST_ROW
    sta currentScreenRow

L1: lda currentScreenRow
    jsr getScreenRowPtr
    sta ptr1
    stx ptr1+1

    lda #' '
    ldy #LIST_COL
    ldx #0
:   sta (ptr1),y
    iny
    inx
    cpx #20
    bne :-

    inc currentScreenRow
    lda currentScreenRow
    cmp #LIST_ROWS+4
    bne L1

    rts
.endproc

.proc clearHelpText
    lda #HELPTEXT_ROW
    sta currentScreenRow

L1: lda currentScreenRow
    jsr getScreenRowPtr
    sta ptr1
    stx ptr1+1

    ldy #0
    lda #' '
L2: sta (ptr1),y
    iny
    cpy #80
    bne L2

    inc currentScreenRow
    lda currentScreenRow
    cmp #HELPTEXT_ROW+6
    bne L1

    rts
.endproc

.proc showHelpText
    lda #<helpText1
    ldx #>helpText1
    ldy #HELPTEXT_ROW
    jsr drawHelpTextRow
    lda #HELPTEXT_ROW
    jsr setRowToForeground

    lda #<helpText2
    ldx #>helpText2
    ldy #HELPTEXT_ROW+1
    jsr drawHelpTextRow
    lda #HELPTEXT_ROW+1
    jsr setRowToForeground

    rts
.endproc

.proc drawHelpTextRow
    pha
    phx
    sty currentScreenRow
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
    lda #HELPTEXT_COL
    sta tmp2
L1: ldy tmp1
    lda (ptr1),y
    beq L2
    jsr petsciiToScreenCode
    ldy tmp2
    sta (ptr2),y
    inc tmp1
    inc tmp2
    bne L1

L2: lda tmp1
    pha
    lda currentScreenRow
    jsr getColorRowPtr
    stq ptr1
    pla
    sta tmp1
    lda #SYNTAXHL_FOREGROUND
    jsr getColorFromTheme
    ldz #HELPTEXT_COL
L3: nop
    sta (ptr1),z
    inz
    dec tmp1
    bne L3

    rts
.endproc

.proc getTheme
    lda #0
    sta topRow

    lda #1
    sta inThemeList

    jsr clearHelpText
    jsr showHelpText

L1: jsr drawThemeList

    jsr getKey
    cmp #KEY_DOWNARROW
    bne :+
    jsr handleDownArrow
    bra L1

:   cmp #KEY_UPARROW
    bne :+
    jsr handleUpArrow
    bra L1

:   cmp #KEY_ENTER
    bne :+
    jsr handleEnter
    jsr clearHelpText
    lda #0
    sta inThemeList
    rts

:   bra L1
.endproc

.proc drawThemeList
    jsr clearList
    jsr refreshThemeList

    rts
.endproc

; This routine returns the color number for the given palette index in the current theme.
.proc getColorFromTheme
    pha
    ldq currentTheme
    stq ptr4
    plx
    dex
    txa
    asl a
    asl a
    clc
    adc #THEME::colors
    taz
    nop
    lda (ptr4),z
    rts
.endproc

.proc refreshThemeList
    lda #0
    sta currentThemeNum

    ; Draw the top border
    lda #LIST_ROW
    jsr getScreenRowPtr
    sta ptr1
    stx ptr1+1
    lda #CH_UPPERLEFT
    ldy #LIST_COL
    sta (ptr1),y
    ldx #0
    lda #CH_HORIZ_LINE
:   iny
    sta (ptr1),y
    inx
    cpx #LIST_WIDTH-2
    bne :-
    lda #CH_UPPERRIGHT
    iny
    sta (ptr1),y
    lda #LIST_ROW
    jsr setRowToForeground

    ; Draw the title row
    lda #LIST_ROW+1
    jsr getScreenRowPtr
    sta ptr1
    stx ptr1+1
    ldy #LIST_COL
    lda #CH_VERT_LINE
    sta (ptr1),y
    ldy #LIST_COL+LIST_WIDTH-1
    sta (ptr1),y
    ldy #LIST_COL+2
    ldx #0
:   lda listTitle,x
    beq :+
    jsr petsciiToScreenCode
    sta (ptr1),y
    iny
    inx
    bne :-
:   lda #LIST_ROW+1
    jsr setRowToForeground

    ; Draw the divider row
    lda #LIST_ROW+2
    jsr getScreenRowPtr
    sta ptr1
    stx ptr1+1
    ldy #LIST_COL
    lda #CH_LEFTSPLIT
    sta (ptr1),y
    iny
    lda #CH_HORIZ_LINE
:   sta (ptr1),y
    iny
    cpy #LIST_COL+LIST_WIDTH-1
    bne :-
    lda #CH_RIGHTSPLIT
    sta (ptr1),y
    lda #LIST_ROW+2
    jsr setRowToForeground

    ; Draw LIST_ROWS number of rows
    lda #LIST_ROW+3
    sta currentScreenRow
    ldq themeList
    stq themePtr
L1: ldq themePtr
    stq ptr2

    ; Is currentThemNum < topRow?
    lda currentThemeNum
    cmp topRow
    bcs :+
    ldz #THEME::next
    neg
    neg
    nop
    lda (ptr2),z
    stq themePtr
    inc currentThemeNum
    bra L1

:   lda #0
    sta selectMask
    lda currentThemeNum
    cmp selectedThemeNum
    bne :+
    lda #$80
    sta selectMask
:   lda currentScreenRow
    jsr getScreenRowPtr
    sta ptr1
    stx ptr1+1
    ldy #LIST_COL
    lda #CH_VERT_LINE
    sta (ptr1),y
    ldy #LIST_COL+LIST_WIDTH-1
    lda #CH_VERT_LINE
    sta (ptr1),y

    ; Is ptr2 null?
    ldq ptr2
    jsr isQZero
    bne :+
    lda currentScreenRow
    jsr setRowToForeground
    inc currentScreenRow
    lda currentScreenRow
    cmp #LIST_HEIGHT-1
    beq L2
    jmp L1
:   ldy #LIST_COL+2
    ldz #THEME::name
    ldx #0
:   nop
    lda (ptr2),z
    jsr petsciiToScreenCode
    ora selectMask
    sta (ptr1),y
    iny
    inz
    cpz #16
    bne :-
    lda currentScreenRow
    jsr setRowToForeground
    ldq themePtr
    stq ptr1
    ldz #THEME::next
    neg
    neg
    nop
    lda (ptr1),z
    stq themePtr
    inc currentScreenRow
    inc currentThemeNum
    lda currentScreenRow
    cmp #LIST_HEIGHT-1
    beq L2
    jmp L1

    ; Draw the bottom row
L2: lda currentScreenRow
    jsr getScreenRowPtr
    sta ptr1
    stx ptr1+1
    lda #CH_LOWERLEFT
    ldy #LIST_COL
    sta (ptr1),y
    ldx #0
    lda #CH_HORIZ_LINE
:   iny
    sta (ptr1),y
    inx
    cpx #LIST_WIDTH-2
    bne :-
    lda #CH_LOWERRIGHT
    iny
    sta (ptr1),y
    lda currentScreenRow
    jsr setRowToForeground

    rts
.endproc

.proc setRowToForeground
    jsr getColorRowPtr
    stq ptr1
    lda #SYNTAXHL_FOREGROUND
    jsr getColorFromTheme
    jsr toVIC
    ldx #0
    ldz #LIST_COL
:   nop
    sta (ptr1),z
    inz
    inx
    cpx #22
    bne :-

    rts
.endproc

.proc handleDownArrow
    lda numThemes
    sta tmp1
    dec tmp1
    lda selectedThemeNum
    cmp tmp1
    bcs :+

    inc selectedThemeNum
    jsr setCurrentTheme
    jsr copyColorsFromTheme
    jsr showHelpText
    jsr refreshScreen

    lda topRow
    clc
    adc #LIST_ROWS-1
    cmp selectedThemeNum
    bcs :+
    inc topRow

:   rts
.endproc

.proc handleUpArrow
    lda selectedThemeNum
    beq :+
    dec selectedThemeNum
    jsr setCurrentTheme
    jsr copyColorsFromTheme
    jsr refreshScreen
    jsr showHelpText
    lda selectedThemeNum
    cmp topRow
    bcs :+
    dec topRow

:   rts
.endproc

.proc handleEnter
    jsr setCurrentTheme
    rts
.endproc

; This routine copies the colors from the currently selected theme,
; in currentTheme, into the VIC color registers.
.proc copyColorsFromTheme
    ldq currentTheme
    stq ptr1

    ; Copy the background color
    lda #SYNTAXHL_BACKGROUND-1
    asl a
    asl a
    clc
    adc #THEME::colors
    taz
    nop
    lda (ptr1),z
    sta VIC_BORDERCOLOR
    sta VIC_BG_COLOR0

    ldz #THEME::colors
    lda #1
    sta tmp1                ; tmp1 is SYNTAXHL_ color index
L2: nop
    lda (ptr1),z
    tax

    ; Red
    inz
    nop
    lda (ptr1),z
    sta $d100,x

    ; Green
    inz
    nop
    lda (ptr1),z
    sta $d200,x

    ; Blue
    inz
    nop
    lda (ptr1),z
    sta $d300,x

    ; Next Color
    inz
    inc tmp1
    lda tmp1
    cmp #10
    bne L2

    rts
.endproc

; This routine copies the color passed in A to the theme.
; X contains the index for the color in the THEME.
.proc copyColorToTheme
    sta tmp1            ; color number in tmp1
    dex
    txa                 ; palette index in A
    asl a               ; multiply by 4
    asl a
    clc
    adc #THEME::colors
    sta tmp2            ; index into THEME::colors in tmp2

    ldq currentTheme
    stq ptr1

    ; Store the color number
    ldz tmp2
    lda tmp1
    nop
    sta (ptr1),z        ; color number

    ; Red component of color
    ldx tmp1
    lda $d100,x
    inz
    nop
    sta (ptr1),z

    ; Green component of color
    lda $d200,x
    inz
    nop
    sta (ptr1),z

    ; Blue component of color
    lda $d300,x
    inz
    nop
    sta (ptr1),z

    rts
.endproc

.proc setCurrentTheme
    ; Walk through the list of themes to find the selected one.
    lda #0
    sta tmp1                ; Current theme number

    ldq themeList
    stq ptr1
L1: ldq ptr1
    jsr isQZero
    bne :+
    rts
:   lda selectedThemeNum
    cmp tmp1
    beq :+
    ; Next theme
    inc tmp1
    ldz #THEME::next
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    bra L1

:   ldq ptr1
    stq currentTheme

    rts
.endproc
