;
; floatsqr.s
; Ken Schenke (kenschenke@gmail.com)
;
; Square a floating point number
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
.include "float.inc"
.include "runtime.inc"

.export floatSqr

.import MOVIND, FPMULT
.proc floatSqr
    lda #FPLSW
    sta FPBASE + FMPNT
    lda #FOPLSW
    sta FPBASE + TOPNT
    ldx #4
    jsr MOVIND
    jmp FPMULT
.endproc
