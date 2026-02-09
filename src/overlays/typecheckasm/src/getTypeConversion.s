;
; getTypeConversion.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"
.include "zeropage.inc"

.export getTypeConversion

.data

; This table is a two-dimensional array indexed by type kind-1.
;    result = typeConversions[leftType-1][rightType-1]
typeConversions: .byte TYPE_CARDINAL, TYPE_CARDINAL, TYPE_CARDINAL, TYPE_LONGINT,  TYPE_CARDINAL, TYPE_LONGINT,  TYPE_REAL
                 .byte TYPE_BYTE,     TYPE_SHORTINT, TYPE_LONGINT,  TYPE_INTEGER,  TYPE_LONGINT,  TYPE_LONGINT,  TYPE_REAL
                 .byte TYPE_WORD,     TYPE_LONGINT,  TYPE_WORD,     TYPE_WORD,     TYPE_CARDINAL, TYPE_LONGINT,  TYPE_REAL
                 .byte TYPE_LONGINT,  TYPE_LONGINT,  TYPE_CARDINAL, TYPE_LONGINT,  TYPE_LONGINT,  TYPE_LONGINT,  TYPE_REAL
                 .byte TYPE_CARDINAL, TYPE_CARDINAL, TYPE_CARDINAL, TYPE_CARDINAL, TYPE_CARDINAL, TYPE_CARDINAL, TYPE_REAL
                 .byte TYPE_LONGINT,  TYPE_LONGINT,  TYPE_LONGINT,  TYPE_LONGINT,  TYPE_CARDINAL, TYPE_LONGINT,  TYPE_REAL
                 .byte TYPE_REAL,     TYPE_REAL,     TYPE_REAL,     TYPE_REAL,     TYPE_REAL,     TYPE_REAL,     TYPE_REAL
.code

; This routine returns the resulting type conversion between two expression types.
; The first expression kind is passed in A and the second in X.
; The resulting expression kind is returned in A.
.proc getTypeConversion
; brk
    dex
    phx
    sta tmp1
    dec tmp1
    lda #0
:   ldx tmp1
    beq :+
    dec tmp1
    clc
    adc #7
    bne :-
:   plx
    stx tmp1
    clc
    adc tmp1
    tax
    lda typeConversions,x
    rts
.endproc
