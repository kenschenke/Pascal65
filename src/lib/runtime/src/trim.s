;
; trim.s
; Ken Schenke (kenschenke@gmail.com)
;
; trim routine for runtime
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;

.include "runtime.inc"

.export trim

startY = tmp3
newLen = tmp2

; This routine counts the length of a string after space characters
; would be removed. It is called before allocating the new string.
; The length is returned in A
; Starting index for first non-space returned in Y.
;
; The string is expected in ptr1
.proc trimmedLen
    ldy #0
    sty newLen
    sty startY          ; index of first non-space
    lda (ptr1),y
    beq RT
    sta tmp1
    ; Loop until a space is found or the string length is reached
:   iny
    inc startY
    lda (ptr1),y
    cmp #' '
    beq :-
    ; The first first non-space is found. Go to the end of the string
    ; and move backwards until a non-space is found or the start is reached.
    ldy #0
    lda (ptr1),y
    tay
:   lda (ptr1),y
    cmp #' '
    bne DN
    dey
    bne :-
    beq RT
DN: tya
    sec
    sbc startY
    sta newLen
    inc newLen
RT: rts
.endproc

; This routine allocates a string object and copies the source.
; The source is passed in A/X.
; The length to copy is passed in Y.
; The new string is returned in A/X.
.proc copyString
    pha
    txa
    pha
    tya
    pha
    ldx #0
    clc
    adc #1
    jsr rtHeapAlloc
    sta ptr2
    stx ptr2 + 1
    pla
    tax
    pla
    sta ptr1 + 1
    pla
    sta ptr1
    ldy #0
    txa
    sta (ptr2),y
    beq DN
:   lda (ptr1),y
    iny
    sta (ptr2),y
    dex
    bne :-
DN: lda ptr2
    ldx ptr2 + 1
    rts
.endproc

; This routine removes leading trailing spaces from a string.
; The source string is passed in A/X.
; The trimmed string is returned in A/X.
; The source string is not modified.
.proc trim
    sta ptr1
    stx ptr1 + 1
    jsr trimmedLen
    lda ptr1
    clc
    adc startY
    bcc :+
    inc ptr1 + 1
:   ldx ptr1 + 1
    ldy newLen
    jmp copyString
.endproc
