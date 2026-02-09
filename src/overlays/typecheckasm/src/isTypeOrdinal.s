;
; isTypeOrdinal.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"

.export isTypeOrdinal

.import isTypeInteger

; This routine sets the Z flag if the TYPE_ in A is an ordinal
.proc isTypeOrdinal
    jsr isTypeInteger
    beq L1
    cmp #TYPE_ENUMERATION
L1: rts
.endproc
