;
; syntaxHex.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; syntaxHex routine

.include "editor.inc"
.include "zeropage.inc"

.export syntaxHex

.import syntaxIndex, syntaxCount, syntaxIsHexDigit

.proc syntaxHex
    ldz syntaxIndex
    lda #SYNTAXHL_NUMBER
    nop
    sta (ptr2),z
    inc syntaxIndex

L1: ldz syntaxIndex
    nop
    lda (ptr1),z
    jsr syntaxIsHexDigit
    bne L2

    lda #SYNTAXHL_NUMBER
    ldz syntaxIndex
    nop
    sta (ptr2),z
    inc syntaxIndex
    lda syntaxIndex
    cpz syntaxCount
    beq L2
    bra L1

L2: rts
.endproc
