; ClearScreen library function

.include "cbm_kernal.inc"

.export clearScreen

; This routine clears the screen

.proc clearScreen
    lda #$93
    jmp CHROUT
.endproc
