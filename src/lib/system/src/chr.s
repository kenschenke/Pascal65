; Chr runtime function

.include "runtime.inc"

.export chr

; This routine returns the low byte of the parameter.

.proc chr
    lda #0
    jsr rtLibLoadParam
    ; Isolate the 1 bit
    pha
    lda #0
    tax
    sta sreg
    stx sreg + 1
    pla
    jmp rtLibReturnValue
.endproc
