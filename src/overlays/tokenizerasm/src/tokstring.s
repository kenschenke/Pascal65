;
; tokstring.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; getStringToken routine

.include "tokenizer.inc"
.include "zeropage.inc"
.include "error.inc"

.export getStringToken

.import tokenCode, tokenString, getChar

.proc compilerError
    rts
.endproc

; This routine tokenizes a string or character literal.
.proc getStringToken
    lda #1
    sta tmp2                ; Use tmp2 as an index into tokenString

    ; Write a quote to the tokenString
    lda #'''
    sta tokenString

L1: jsr getChar
    cmp #CH_EOF
    beq L4
    cmp #'''                ; Look for another quote
    bne L2
    ; Fetched a quote. Now check for an adjacent quote,
    ; since two consecutive quotes represent a single
    ; quote in a string.
    jsr getChar
    cmp #'''
    bne L3
L2: ; Append the character to the string
    ldx tmp2
    sta tokenString,x
    inc tmp2
    bra L1

L3: ; End of string reached. Write a closing quote
    ldx tmp2
    lda #'''
    sta tokenString,x
    inx
    lda #0
    sta tokenString,x
    lda #tcString
    sta tokenCode
    rts

L4: lda #errUnexpectedEndOfFile
    jsr compilerError
    rts
.endproc
