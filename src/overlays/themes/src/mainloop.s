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
    ldx #THEME_COLORS
L2: cmp colorKeys-1,x
    beq L3
    dex
    bne L2
    bra L1                      ; Not a color's key
L3: jsr handlePaletteSelection  ; X is the key's SYNTAXHL_* color
    bra L1
.endproc

.data

; The key for each color, in SYNTAXHL_* order (editor.inc): Numbers,
; Keywords, Strings, Comments, Operators, Identifiers, cursor (R),
; Foreground, Background, Error and Warning
colorKeys: .byte "nkscoirfbew"
.assert * - colorKeys = THEME_COLORS, error, "colorKeys needs a key per color"

.code

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
