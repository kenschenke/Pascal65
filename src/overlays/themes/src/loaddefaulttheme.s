;
; loaddefaulttheme.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Load default theme colors into VIC color registers

.include "editor.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export loadDefaultTheme

.import initThemeList, freeThemeList, currentTheme, toVIC

; This routine reads the theme list and loads the colors
; from the default them into the VIC color registers.
;
; The caller passes in a pointer to a buffer of at least 10 bytes.
; The color numbers are stored in the buffer passed by the caller.
; The first byte is ignored, the rest of the bytes contain the color numbers.
; The buffer is indexed by the SYNTAXHL_* constants.
.proc loadDefaultTheme
    ; Save the caller's buffer pointer
    pha
    phx

    ; Read the theme list and load the default theme
    jsr initThemeList

    ; Copy the theme colors into the caller's buffer
    ; Restore the caller's buffer pointer after copying the theme colors
    pla
    sta ptr2+1
    pla
    sta ptr2
    jsr copyThemeColors

    ; Free the theme list
    jsr freeThemeList

    rts
.endproc

.proc copyThemeColors
    ldq currentTheme
    stq ptr1

    lda #1
    sta tmp1            ; tmp1 = index into caller's buffer

    ldz #THEME::colors

    ; Loop through the theme colors and copy them into the caller's buffer
L1: nop
    lda (ptr1),z
    jsr toVIC
    ldy tmp1
    sta (ptr2),y
    inz

    inc tmp1
    ; Skip past the RGB values (3 bytes)
    inz
    inz
    inz

    lda tmp1
    cmp #10
    bne L1

    rts
.endproc
