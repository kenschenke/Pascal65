;
; themefile.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Read and write theme files

.include "c64.inc"
.include "asmlib.inc"
.include "editor.inc"
.include "zeropage.inc"
.include "4510macros.inc"
.include "cbm_kernal.inc"

.export readThemeFile, writeThemeFile, resetToDefaults

.import themeList, selectedThemeNum, numThemes, copyColorsFromTheme
.import setCurrentTheme, freeThemeList, resetSystemPalette

; Theme files are little more than just dumps of the THEME structure.
;
; Version 1 (THEME_VERSION) starts with THEME_MARKER ($FF), the version
; and the zero-based number of the theme selected for the editor. Then
; come THEME_SIZE-byte themes until the end of the file.
;
; Version 0, the old file, has no marker. It starts with the selected
; theme number, which is never $FF, and its themes are THEME_SIZE_V0 bytes:
; no error or warning color. Each gets copies of its UI color as those
; (see addRecord). writeThemeFile always writes version 1.
;
; A file that is missing, has another version, or has no complete theme,
; is unreadable. Then
; themes.dat falls back to themes.def, and themes.def to the built-in
; theme, so the list always has at least one theme. A partial theme at the
; end of a file is dropped. setCurrentTheme puts a selected number past
; the end of the list back to 0.

.bss

lastTheme: .res 4
filenamePtr: .res 2
recordPos: .res 1           ; The bytes of the record read so far
recordLen: .res 1           ; THEME_SIZE, or THEME_SIZE_V0 in version 0

.data

strFilename: .asciiz "themes.dat"
strDefFilename: .asciiz "themes.def"

; The theme used when neither file can be read
builtinTheme:
    .byte "Default         "
    .byte  5,  0, 15,  0    ; SYNTAXHL_NUMBER
    .byte  4, 15,  9, 12    ; SYNTAXHL_KEYWORD
    .byte  3,  0, 15, 15    ; SYNTAXHL_STRING
    .byte 12, 10, 10, 10    ; SYNTAXHL_COMMENT
    .byte  1, 13, 13, 13    ; SYNTAXHL_OPERATOR
    .byte 10, 15, 10,  7    ; SYNTAXHL_IDENTIFIER
    .byte 19, 14, 14,  0    ; SYNTAXHL_CURSOR
    .byte  1, 13, 13, 13    ; SYNTAXHL_FOREGROUND
    .byte 21,  2,  3,  5    ; SYNTAXHL_BACKGROUND
    .byte  1, 13, 13, 13    ; SYNTAXHL_ERROR, the UI color for now
    .byte  1, 13, 13, 13    ; SYNTAXHL_WARNING, the UI color for now
.assert * - builtinTheme = THEME_SIZE, error, "builtinTheme is the wrong size"

.code

; Reads themes.dat into themeList. If it can't be read, the defaults are
; read instead (see readDefaults).
.proc readThemeFile
    lda #<strFilename
    sta filenamePtr
    lda #>strFilename
    sta filenamePtr+1

    jsr readThemeFileX
    lda numThemes
    beq readDefaults
    rts
.endproc

; Reads themes.def into themeList. If it can't be read, the list is the
; built-in theme.
.proc readDefaults
    lda #<strDefFilename
    sta filenamePtr
    lda #>strDefFilename
    sta filenamePtr+1

    jsr readThemeFileX
    lda numThemes
    beq :+
    rts

    ; The built-in theme
:   sta selectedThemeNum
    jsr allocTheme
    ldz #0
L1: tza
    tax
    lda builtinTheme,x
    nop
    sta (ptr1),z
    inz
    cpz #THEME_SIZE
    bne L1
    jmp addTheme
.endproc

.proc resetToDefaults
    jsr freeThemeList
    jsr readDefaults
    jsr setCurrentTheme
    jsr resetSystemPalette
    jmp copyColorsFromTheme
.endproc

; Allocates a theme in ptr1. heapAlloc zeros it, so THEME::next is null.
.proc allocTheme
    lda #.sizeof(THEME)
    ldx #0
    jsr heapAlloc
    stq ptr1
    rts
.endproc

; Adds the theme in ptr1 to the end of the list
.proc addTheme
    inc numThemes
    ldq themeList
    jsr isQZero
    bne L1              ; Branch if there is already a theme in the list
    ldq ptr1
    stq themeList
    stq lastTheme
    rts

L1: ldq lastTheme
    stq ptr2
    ldx #0
    ldz #THEME::next
:   lda ptr1,x
    nop
    sta (ptr2),z
    inz
    inx
    cpx #4
    bne :-
    ldq ptr1
    stq lastTheme
    rts
.endproc

; Reads the file filenamePtr names into themeList. The list is empty if
; the file doesn't exist, has another version or has no complete theme.
.proc readThemeFileX
    ; Initialize the theme list
    lda #0
    tax
    tay
    taz
    stq themeList
    sta numThemes

    lda filenamePtr
    ldx filenamePtr+1
    ldy #0
    ldz #0
    jsr doesFileExist
    bne :+
    rts

:   lda filenamePtr
    ldx filenamePtr+1
    ldy #0
    ldz #0
    sec
    jsr makeFilename
    jsr SETNAM
    ldx DEVNUM
    lda #1
    tay
    iny
    jsr SETLFS
    jsr OPEN
    ldx #1
    jsr CHKIN

    ; The header. Themes must follow it.
    jsr readByte
    bne CL
    cmp #THEME_MARKER
    beq V1
    ldx #THEME_SIZE_V0  ; Version 0: A is the selected number
    bra SL
V1: jsr readByte
    bne CL
    cmp #THEME_VERSION
    bne CL              ; Another version: unreadable
    jsr readByte
    bne CL
    ldx #THEME_SIZE
SL: sta selectedThemeNum
    stx recordLen

    ; Read a theme
L1: jsr allocTheme
    lda #0
    sta recordPos
L2: jsr CHRIN
    ldz recordPos
    nop
    sta (ptr1),z
    inc recordPos
    lda STATUS
    bne EF              ; The end of the file, or an error
    lda recordPos
    cmp recordLen
    bne L2
    jsr addRecord
    bra L1

    ; The last byte of the file is good. It must end a theme.
EF: and #$40
    beq PT              ; A read error
    lda recordPos
    cmp recordLen
    bne PT
    jsr addRecord
    bra CL

    ; Drop a partial theme
PT: ldq ptr1
    jsr heapFree

CL: lda #1
    jsr CLOSE
    jmp CLRCHN
.endproc

; Reads a byte of the file into A. The Z flag is clear if it was the last
; byte or the read failed (STATUS isn't zero). X is lost.
.proc readByte
    jsr CHRIN
    ldx STATUS
    rts
.endproc

; The offset of the UI color in a THEME
UI_COLOR = THEME::colors + (SYNTAXHL_FOREGROUND - 1) * THEME_COLOR_SIZE

; addRecord fills in the colors past the end of a version 0 theme, and
; finds each byte's source by its offset in the color.
.assert SYNTAXHL_ERROR = THEME_COLORS_V0 + 1, error, "error isn't first new"
.assert SYNTAXHL_WARNING = THEME_COLORS, error, "warning isn't last"
.assert THEME_COLOR_SIZE = 4, error, "addRecord assumes 4-byte colors"
.assert (UI_COLOR & 3) = 0, error, "addRecord assumes UI_COLOR is aligned"

; Adds the theme just read, in ptr1, to the list. A version 0 theme first
; gets copies of its UI color as its error and warning colors.
.proc addRecord
    ldx recordLen
    cpx #THEME_SIZE
    beq DN
    ; X is THEME_SIZE_V0, the first byte of the error color
L1: txa
    and #THEME_COLOR_SIZE-1
    ora #UI_COLOR
    taz
    nop
    lda (ptr1),z        ; The same byte of the UI color
    phx
    plz
    nop
    sta (ptr1),z
    inx
    cpx #THEME_SIZE
    bne L1
DN: jmp addTheme
.endproc

.proc writeThemeFile
    ; Delete the existing theme file
    lda #<strFilename
    ldx #>strFilename
    ldy #0
    ldz #0
    stq ptr1
    jsr scratchFile

    ; Open the file for writing
    lda #<strFilename
    ldx #>strFilename
    ldy #0
    ldz #0
    clc
    jsr makeFilename
    jsr SETNAM
    ldx DEVNUM
    lda #1
    tay
    iny
    jsr SETLFS
    jsr OPEN
    ldx #1
    jsr CHKOUT

    ; The version 1 header and the selected theme number
    lda #THEME_MARKER
    jsr CHROUT
    lda #THEME_VERSION
    jsr CHROUT
    lda selectedThemeNum
    jsr CHROUT

    ; Write the themes
    ldq themeList
    stq ptr1
L1: ldq ptr1
    jsr isQZero
    bne L2

    ; Close the file
    lda #1
    jsr CLOSE
    jmp CLRCHN

L2: ldz #0
L3: nop
    lda (ptr1),z
    jsr CHROUT
    inz
    cpz #THEME_SIZE
    bne L3

    ; Next theme
    ldz #THEME::next
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    bra L1
.endproc
