;
; record.s
; Ken Schenke (kenschenke@gmail.com)
;
; Record routines
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;

.include "runtime.inc"

.export calcRecordOffset

.import popax

; This routine calculates the address of a field in a record's
; heap buffer. It expects the field offset to be pushed onto the
; runtime stack and the record heap address to be passed in A/X.
;
; The address in the record's heap is returned in A/X.
.proc calcRecordOffset
    sta ptr1
    stx ptr1 + 1
    jsr popax
    sta tmp1
    stx tmp2
    lda ptr1
    clc
    adc tmp1
    pha
    lda ptr1 + 1
    adc tmp2
    tax
    pla
    rts
.endproc
