;
; floatabs.s
; Ken Schenke (kenschenke@gmail.com)
;
; Floating point absolute value
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "float.inc"
.include "runtime.inc"

.export floatAbs

.import floatNeg

.proc floatAbs
    lda FPBASE + FPMSW
    and #$80                ; Check for high bit in MSB
    beq L1                  ; If not set, jump ahead
    jmp floatNeg
L1:
    rts
.endproc
