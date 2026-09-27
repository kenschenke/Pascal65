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

.import themeList, selectedThemeNum, numThemes, copyColorsFromTheme, setCurrentTheme, freeThemeList

; Theme files are little more than just dumps of the THEME structure.
;
; The first byte of the theme file is the zero-based theme number
; that is currently selected for the editor.
;
; Following the theme number, the file consists of THEME structures.

.bss

lastTheme: .res 4
filenamePtr: .res 2

.data

strFilename: .asciiz "themes.dat"
strDefFilename: .asciiz "themes.def"

.code

.proc readThemeFile
    lda #<strFilename
    sta filenamePtr
    lda #>strFilename
    sta filenamePtr+1

    jmp readThemeFileX
.endproc

.proc resetToDefaults
    jsr freeThemeList

    lda #<strDefFilename
    sta filenamePtr
    lda #>strDefFilename
    sta filenamePtr+1

    jsr readThemeFileX

    jsr setCurrentTheme
    jsr copyColorsFromTheme

    rts
.endproc

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

    ; Read the themes
L1: jsr CHRIN
    ldy STATUS
    cpy #$40
    bne :+              ; Branch if not EOF
    lda #1
    jsr CLOSE
    ldx #0
    jsr CHKIN
    rts
:   pha                 ; Save the first byte of the theme
    lda #.sizeof(THEME)
    ldx #0
    jsr heapAlloc
    stq ptr1
    ldz #0
    pla
    nop
    sta (ptr1),z

    ; Set THEME::next to null
    lda #0
    tax
    ldz #THEME::next
:   nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-

    ; Read the rest of the theme
    lda #THEME_SIZE-1
    sta tmp1
    lda #1
    sta tmp2
L2: jsr CHRIN
    ldz tmp2
    nop
    sta (ptr1),z
    inc tmp2
    dec tmp1
    bne L2

    ; Add the theme to the linked list
    inc numThemes
    ldq themeList
    jsr isQZero
    bne L3              ; Branch if there is already a theme in the list
    ldq ptr1
    stq themeList
    stq lastTheme
    bra L1

L3: ldq lastTheme
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
    jmp L1
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
    ldx #0
    jsr CHKOUT
    rts

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
