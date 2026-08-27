;
; tokcharvalue.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; getCharValueToken routine

.include "tokenizer.inc"

.export getCharValueToken

.import getNumberToken, getHexToken, getChar, putBackChar
.import tokenCode, tokenValue, tokenString

; This routine tokenizes a character literal. The caller has already consumed the #.
; If the literal starts with a $ then the value is tokenized as a hex value. Otherwise,
; base ten number tokenization is used.
;
; On exit, tokenCode contains tcString and tokenString contains the character literal
; in quotes.
.proc getCharValueToken
    jsr getChar
    cmp #'$'
    bne L1
    jsr getHexToken
    bra L2

L1: clc
    jsr getNumberToken

L2: lda #'''
    sta tokenString
    sta tokenString+2
    lda tokenValue
    sta tokenString+1
    lda #0
    sta tokenString+3
    lda #tcString
    sta tokenCode
    rts
.endproc
