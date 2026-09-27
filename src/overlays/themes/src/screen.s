;
; screen.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Draw screen and handle help text

.include "asmlib.inc"
.include "editor.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

; Screen codes for the drawing characters
CH_UPPERLEFT = $70
CH_UPPERRIGHT = $6e
CH_LOWERLEFT = $6d
CH_LOWERRIGHT = $7d
CH_VERTBAR = $5d
CH_HORIZBAR = $40
CH_LEFTSPLIT = $6b
CH_RIGHTSPLIT = $73

; Help Text
HELPTEXT_ROW = 17
HELPTEXT_COL = 3

.export initScreen, getScreenRowPtr, getColorRowPtr, refreshScreen
.export petsciiToScreenCode

.import drawCodeSample, drawColorPalette, inPaletteMode, inThemeList
.import getColorFromTheme, toVIC

.data

helpText1:
    .asciiz " C:Comments     K:Keywords   I:Identifiers"
helpText2:
    .asciiz " B:Background   R:Cursor     O:Operators"
helpText3:
    .asciiz " S:Strings      N:Numbers    F:Foreground"
helpText4:
    .asciiz "F1:Save+Exit   F5:Themes    F8:Reset to Defaults"
helpText5:
    .asciiz "On exit, current theme will be the default"

.code

.proc initScreen
    ; Clear the screen
    lda #147
    jsr CHROUT

    jsr refreshScreen

    rts
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
    cpy #45
    bne L1
    rts
.endproc

.proc drawHelpText
    jsr clearHelpText

    lda #<helpText1
    ldx #>helpText1
    ldy #HELPTEXT_ROW
    jsr drawHelpTextRow

    lda #<helpText2
    ldx #>helpText2
    ldy #HELPTEXT_ROW+1
    jsr drawHelpTextRow

    lda #<helpText3
    ldx #>helpText3
    ldy #HELPTEXT_ROW+2
    jsr drawHelpTextRow

    lda #<helpText4
    ldx #>helpText4
    ldy #HELPTEXT_ROW+4
    jsr drawHelpTextRow

    lda #<helpText5
    ldx #>helpText5
    ldy #HELPTEXT_ROW+5
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

.proc refreshScreen
    jsr drawCodeSample
    lda inThemeList
    bne :+
    jsr drawColorPalette
:   lda inPaletteMode
    bne :+
    lda inThemeList
    bne :+
    jsr drawHelpText
:   rts
.endproc

; This routine returns the address for the screen RAM
; for the row in A.
;
; Address returned in A/X
.proc getScreenRowPtr
    ; Multiply row * 80
    sta intOp2
    lda #0
    sta intOp2+1
    sta intOp1+1
    lda #80
    sta intOp1
    jsr multInt16

    ; Add to $800
    lda #0
    sta intOp2
    lda #8
    sta intOp2+1
    jsr addInt16

    ; Return the address
    lda intOp1
    ldx intOp1+1
    rts
.endproc

; This routine returns the address for the color RAM
; for the row in A.
;
; Address returned in Q
.proc getColorRowPtr
    ; Multiply row * 80
    sta intOp2
    lda #0
    sta intOp2+1
    sta intOp1+1
    lda #80
    sta intOp1
    jsr multInt16

    ; Add to $F F8 00 00
    lda #0
    sta intOp32
    lda #0
    sta intOp32+1
    lda #$f8
    sta intOp32+2
    lda #$0f
    sta intOp32+3

    lda intOp1
    ldx intOp1+1
    ldy #0
    ldz #0
    clc
    adcq intOp32

    rts
.endproc

.proc petsciiToScreenCode
    cmp #$20
    bcc RV              ; branch is A < 32 (reverse character)

    cmp #$60
    bcc B1              ; branch if A < 96 (clear bits 6 and 7)

    cmp #$80
    bcc B2              ; branch if A < 128

    cmp #$a0
    bcc B3              ; branch if A < 160

    cmp #$c0
    bcc B4              ; branch if A < 192

    cmp #$ff
    bcc RV              ; branch if A < 255
    
    lda #$7e            ; set A = 126
    bne DN

B2: and #$5f            ; clear bits 5 and 7
    bne DN

B3: ora #$40            ; if A between 128 and 159, set bit 6
    bne DN

B4: eor #$c0            ; if A between 160 and 191, flip bits 6 and 7
    bne DN

B1: and #$3f            ; clear bits 6 and 7
    bpl DN

RV: eor #$80            ; flip bit 7
DN: rts   
.endproc
