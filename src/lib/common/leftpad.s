.include "cbm_kernal.inc"

.importzp tmp1

.export leftpad

; Left pad a field with spaces.
; Field width in .A
; Value width in .X
; tmp1 is clobbered
.proc leftpad
    stx tmp1
    cmp tmp1
    bmi Done
    sec
    sbc tmp1
    tay
    lda #' '
Loop:
    dey
    bmi Done
    jsr CHROUT
    jmp Loop

Done:
    rts
.endproc