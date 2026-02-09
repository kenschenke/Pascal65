;
; isTypeNumeric.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"

.export isTypeNumeric

.import isTypeInteger

; This routine sets the Z flag if the TYPE_ in A is a numeric type (integer or real)
.proc isTypeNumeric
    jsr isTypeInteger
    beq L1

    cmp #TYPE_REAL
L1: rts
.endproc
