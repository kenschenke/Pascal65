;
; syntaxString.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; syntaxString routine

.include "editor.inc"
.include "zeropage.inc"

.export syntaxString

.import syntaxIndex, syntaxCount, syntaxIsNextChar

.proc syntaxString
    lda #SYNTAXHL_STRING
    nop
    sta (ptr2),z
    inc syntaxIndex

    ; Loop until the end of the string or line
L1: ldz syntaxIndex
    cmp syntaxCount
    bne L2
    rts

L2: nop
    lda (ptr1),z
    cmp #'''
    bne L3
    ; Is the next character also a quote
    ldx #'''
    jsr syntaxIsNextChar
    bne :+
    ; Escaped quote
    ldz syntaxIndex
    lda #SYNTAXHL_STRING
    nop
    sta (ptr2),z
    inc syntaxIndex
    inz
    nop
    sta (ptr2),z
    inc syntaxIndex
    bra L1
    ; End of the string
:   lda #SYNTAXHL_STRING
    ldz syntaxIndex
    nop
    sta (ptr2),z
    inc syntaxIndex
    rts

L3: ldz syntaxIndex
    lda #SYNTAXHL_STRING
    nop
    sta (ptr2),z
    inc syntaxIndex
    bra L1
.endproc
