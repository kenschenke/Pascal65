; Odd runtime function

.include "runtime.inc"

.export odd

; This routine returns a non-zero value if the paramater is odd

.proc odd
    lda #0
    jsr rtLibLoadParam
    ; Isolate the 1 bit
    and #1
    pha
    lda #0
    tax
    sta sreg
    stx sreg + 1
    pla
    jmp rtLibReturnValue
.endproc
