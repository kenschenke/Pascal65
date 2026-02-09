;
; getTypeSize.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"

.export getTypeSize

; Type kind passed in A.
; Size returned in A/X.
.proc getTypeSize
    ldx #0
    cmp #TYPE_REAL
    bne :+
    lda #4
    rts
:   cmp #TYPE_SHORTINT
    bne :+
    lda #1
    rts
:   cmp #TYPE_BYTE
    bne :+
    lda #1
    rts
:   cmp #TYPE_INTEGER
    bne :+
    lda #2
    rts
:   cmp #TYPE_WORD
    bne :+
    lda #2
    rts
:   cmp #TYPE_LONGINT
    bne :+
    lda #4
    rts
:   cmp #TYPE_CARDINAL
    bne :+
    lda #4
    rts
:   lda #0
    rts
.endproc
