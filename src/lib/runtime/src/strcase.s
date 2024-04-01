;
; strcase.s
; Ken Schenke (kenschenke@gmail.com)
;
; String alphabetic case
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;

.include "runtime.inc"

.export strCase

.import isAlpha

len = tmp1
upper = tmp2

; This routine copies a string passed in A/X and switches alphabetic
; characters to upper or lower case.
; Y: 1 for upper case, 0 for lower case
;
; The new string is returned in A/X.
.proc strCase
    sta ptr1
    pha
    stx ptr1 + 1
    txa
    pha
    tya
    pha
    ldy #0
    lda (ptr1),y
    pha
    clc
    adc #1
    ldx #0
    jsr rtHeapAlloc
    sta ptr2
    stx ptr2 + 1
    pla
    sta len
    pla
    sta upper
    pla
    sta ptr1 + 1
    pla
    sta ptr1
    ldy #0
    lda len
    sta (ptr2),y
    beq DN
LP: iny
    lda (ptr1),y
    jsr isAlpha
    cpx #0
    beq ST
    ldx upper
    bne UP
    and #$7f
    bne ST
UP: ora #$80
ST: sta (ptr2),y
    dec len
    bne LP
DN: lda ptr2
    ldx ptr2 + 1
    rts
.endproc
