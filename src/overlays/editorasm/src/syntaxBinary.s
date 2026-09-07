;
; syntaxBinary.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; syntaxBinary routine

.include "editor.inc"
.include "zeropage.inc"

.export syntaxBinary

.import syntaxIndex, syntaxCount

.proc syntaxBinary
    ldz syntaxIndex
    lda #SYNTAXHL_NUMBER
    nop
    sta (ptr2),z
    inc syntaxIndex

L1: ldz syntaxIndex
    nop
    lda (ptr1),z
    cmp #'0'
    beq L2
    cmp #'1'
    bne L3

L2: lda #SYNTAXHL_NUMBER
    ldz syntaxIndex
    nop
    sta (ptr2),z
    inc syntaxIndex
    lda syntaxIndex
    cpz syntaxCount
    beq L3
    bra L1

L3: rts
.endproc
