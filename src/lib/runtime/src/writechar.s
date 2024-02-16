.include "cbm_kernal.inc"

.export writeChar

.import leftpad

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
