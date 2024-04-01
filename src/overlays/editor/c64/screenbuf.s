;
; screenbuf.s
; Ken Schenke (kenschenke@gmail.com)
;
; Screen buffer routines for editor
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;


.include "cbm_kernal.inc"

.import popa, petscii2Screen
.importzp ptr1, tmp1
; ptr1: screen

.export _screenInsertChar, _screenDeleteChar

; Row number (0-based) in X
; Address returned in ptr1
.proc calcRowAddr
    inx                     ; Add one to row
    ; Start with ptr1 at $400 (base of screen memory)
    lda #0
    sta ptr1
    lda #4
    sta ptr1 + 1
    ; Add 40 for every row
L1:
    dex                     ; Decrement row
    beq L2                  ; Branch if zero
    lda ptr1                ; Add 40 to ptr1
    clc
    adc #40
    sta ptr1
    lda ptr1 + 1
    adc #0
    sta ptr1 + 1
    jmp L1
L2:
    rts
.endproc

; void screenDeleteChar(char ch, char col, char row)
.proc _screenDeleteChar
    tax                     ; Copy row to X
    jsr calcRowAddr
    jsr popa                ; Pop col number off call stack
    sta tmp1                ; Store it in tmp1
    lda #40                 ; Start at column 40
    sec                     ; Clear for subtraction
    sbc tmp1                ; 40 - column = # of chars to copy
    beq L2                  ; Branch if no chars to copy
    tax                     ; # of chars to copy in X
    ldy tmp1                ; Start at next to last column
L1:
    iny
    lda (ptr1),y
    dey
    sta (ptr1),y
    iny
    dex
    bne L1
L2:
    jsr popa
    ldy #39
    jsr petscii2Screen
    sta (ptr1),y
    rts
.endproc

; void screenInsertChar(char ch, char col, char row)
.proc _screenInsertChar
    tax                     ; Copy row to X
    jsr calcRowAddr
    jsr popa                ; Pop col number off call stack
    sta tmp1                ; Store it in tmp1
    ldy #$ff
    lda #40                 ; Start at column 40
    sec                     ; Clear for subtraction
    sbc tmp1                ; 40 - column = # of chars to copy
    beq L2                  ; Branch if no chars to copy
    tax                     ; # of chars to copy in X
    ldy #39                 ; Start at next to last column
L1:
    dey
    lda (ptr1),y
    iny
    sta (ptr1),y
    dey
    dex
    bne L1
L2:
    iny
    sty tmp1
    jsr popa
    jsr petscii2Screen
    ldy tmp1
    sta (ptr1),y
    rts
.endproc
