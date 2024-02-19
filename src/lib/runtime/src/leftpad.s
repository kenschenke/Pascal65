.include "runtime.inc"

.export leftpad

.import writeByte

; Left pad a field with spaces.
; Field width in .A
; Value width in .X
; tmp1 is clobbered
.proc leftpad
    cmp #0
    beq Done
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
    jsr writeByte
    clc
    bcc Loop

Done:
    rts
.endproc
