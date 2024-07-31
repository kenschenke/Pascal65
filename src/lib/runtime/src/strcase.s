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
    ; Save source string pointer in ptr1 and on CPU stack
    sta ptr1
    pha
    stx ptr1 + 1
    txa
    pha
    ; Save upper/lower flag on CPU stack
    tya
    pha
    ldy #0
    lda (ptr1),y        ; Load source string length
    pha                 ; Save it on CPU stack
    clc
    adc #1              ; Add one to it
    ldx #0
    jsr rtHeapAlloc     ; Allocate a new string
    sta ptr2
    stx ptr2 + 1        ; Save new string in ptr2
    pla                 ; Pop source string length off CPU stack
    sta len             ; Keep it in "len"
    pla                 ; Pop upper/lower flag off CPU stack
    sta upper           ; Keep it in "upper"
    pla                 ; Pop source string pointer off CPU stack
    sta ptr1 + 1        ; Store it in ptr1
    pla
    sta ptr1
    ldy #0
    lda len             ; Put length in destination string
    sta (ptr2),y
    beq DN
LP: iny
    lda (ptr1),y        ; Load next character from source string
    jsr isAlpha         ; Is it an alphabetic character?
    cpx #0
    beq ST              ; Branch if not
    ldx upper           ; Check if caller wants uppercase
    bne UP              ; Branch if so
    and #$7f            ; Set letter to lowercase
    bne ST              ; Branch to store
UP: ora #$80            ; Set letter to uppercase
ST: sta (ptr2),y        ; Store the character
    dec len             ; Decrement length
    bne LP              ; Branch if more characters in string
DN: lda ptr2            ; Load destination string pointer
    ldx ptr2 + 1
    rts
.endproc
