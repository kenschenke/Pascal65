.include "runtime.inc"

.export calcRecordOffset

; This routine calculates the address of a field in a record's
; heap buffer. It expects the field offset to be pushed onto the
; runtime stack and the record heap address to be passed in A/X.
;
; The address in the record's heap is returned in A/X.
.proc calcRecordOffset
    sta ptr1
    stx ptr1 + 1
    jsr rtPopAx
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
