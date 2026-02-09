;
; isTypeInteger.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"

.export isTypeInteger

; This routine sets the Z flag if the TYPE_ kind in A is an integer type.
.proc isTypeInteger
    cmp #TYPE_SHORTINT
    beq L1
    cmp #TYPE_BYTE
    beq L1
    cmp #TYPE_INTEGER
    beq L1
    cmp #TYPE_WORD
    beq L1
    cmp #TYPE_LONGINT
    beq L1
    cmp #TYPE_CARDINAL
L1: rts
.endproc
