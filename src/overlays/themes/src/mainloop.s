;
; mainloop.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Main loop for handling theme editing

.include "editor.inc"

.export mainloop, toVIC

.import getKey, getPaletteColor, fixAlphaCase, refreshScreen, getColorFromTheme
.import getTheme, writeThemeFile, resetToDefaults

.proc mainloop
    jsr getTheme
    jsr refreshScreen

    ; Loop, processing keys
L1: jsr getKey
    cmp #CH_F1
    bne :+
    jsr writeThemeFile
    rts
:   cmp #CH_F5
    bne :+
    jsr getTheme
    jsr refreshScreen
    bra L1
:   cmp #CH_F8
    bne :+
    jsr resetToDefaults
    jsr refreshScreen
    bra L1
:   jsr fixAlphaCase
    and #$7f                    ; Convert to lowercase
    cmp #'k'
    bne :+
    jsr handleKeywords
    bra L1
:   cmp #'c'
    bne :+
    jsr handleComments
    bra L1
:   cmp #'n'
    bne :+
    jsr handleNumbers
    bra L1
:   cmp #'s'
    bne :+
    jsr handleStrings
    bra L1
:   cmp #'r'
    bne :+
    jsr handleCursor
    bra L1
:   cmp #'o'
    bne :+
    jsr handleOperators
    bra L1
:   cmp #'i'
    bne :+
    jsr handleIdentifiers
    bra L1
:   cmp #'b'
    bne :+
    jsr handleBackground
    bra L1
:   cmp #'f'
    bne :+
    jsr handleForeground
    bra L1

:   bra L1
.endproc

.proc handleBackground
    ldx #SYNTAXHL_BACKGROUND
    jsr handlePaletteSelection
    rts
.endproc

.proc handleComments
    ldx #SYNTAXHL_COMMENT
    jsr handlePaletteSelection
    rts
.endproc

.proc handleCursor
    ldx #SYNTAXHL_CURSOR
    jsr handlePaletteSelection
    rts
.endproc

.proc handleKeywords
    ldx #SYNTAXHL_KEYWORD
    jsr handlePaletteSelection
    rts
.endproc

.proc handleNumbers
    ldx #SYNTAXHL_NUMBER
    jsr handlePaletteSelection
    rts
.endproc

.proc handleOperators
    ldx #SYNTAXHL_OPERATOR
    jsr handlePaletteSelection
    rts
.endproc

.proc handleIdentifiers
    ldx #SYNTAXHL_IDENTIFIER
    jsr handlePaletteSelection
    rts
.endproc

.proc handleStrings
    ldx #SYNTAXHL_STRING
    jsr handlePaletteSelection
    rts
.endproc

.proc handleForeground
    ldx #SYNTAXHL_FOREGROUND
    jsr handlePaletteSelection
    rts
.endproc

; This is a helper routine than handles calling the palette selector
; for a given syntax highlight category such as SYNTAXHL_KEYWORD.
; The category is passed in X.
.proc handlePaletteSelection
    phx
    txa
    jsr getColorFromTheme
    plx
    jsr getPaletteColor
    jsr refreshScreen
    rts
.endproc

.proc toVIC
    bit #%11110000
    bne :+
    rts
:   and #%00001111
    ora #%01000000
    rts
.endproc
