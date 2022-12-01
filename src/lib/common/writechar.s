.include "cbm_kernal.inc"

.import leftpad
.export writeChar

; Write character output.
; Character in .A
; Field width in .X
.proc writeChar
    pha
    txa
    ldx #1
    jsr leftpad
    pla
    jsr CHROUT
    rts
.endproc
