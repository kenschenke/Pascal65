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
; The first byte of the theme file is the zero-based theme number
; that is currently selected for the editor.
;
; Following the theme number, the file consists of THEME structures.
;
; A file that is missing, or has no complete theme, is unreadable. Then
; themes.dat falls back to themes.def, and themes.def to the built-in
; theme, so the list always has at least one theme. A partial theme at the
; end of a file is dropped. setCurrentTheme puts a selected number past
; the end of the list back to 0.

.bss

lastTheme: .res 4
filenamePtr: .res 2
recordPos: .res 1           ; The bytes of the record read so far

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
; the file doesn't exist or has no complete theme.
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

    ; Read the selected theme number
    jsr CHRIN
    sta selectedThemeNum
    lda STATUS
    bne CL              ; Nothing follows it

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
    cmp #THEME_SIZE
    bne L2
    jsr addTheme
    bra L1

    ; The last byte of the file is good. It must end a theme.
EF: and #$40
    beq PT              ; A read error
    lda recordPos
    cmp #THEME_SIZE
    bne PT
    jsr addTheme
    bra CL

    ; Drop a partial theme
PT: ldq ptr1
    jsr heapFree

CL: lda #1
    jsr CLOSE
    jmp CLRCHN
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

    ; Write the selected theme number
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
