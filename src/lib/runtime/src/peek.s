; This routine retrieves a value from a provided memory address.

; Inputs:
;    The memory address is passed in A/X
;
; Outputs:
;    The value is returned in A.

.include "runtime.inc"

.export peek

.proc peek
    sta ptr1
    stx ptr1 + 1
    ldy #0
    lda (ptr1),y
    rts
.endproc
