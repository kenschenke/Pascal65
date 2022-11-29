.include "cbm_kernal.inc"

.import leftpad
.export writechar

; Write character output.
; Character in .A
; Field width in .X
.proc writechar
    pha
    txa
    ldx #1
    jsr leftpad
    pla
    jsr CHROUT
    rts
.endproc
