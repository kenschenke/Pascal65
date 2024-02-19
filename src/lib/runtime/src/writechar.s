.include "cbm_kernal.inc"

.export writeChar

.import leftpad, writeByte

; Write character output.
; Character in .A
; Field width in .X
.proc writeChar
    pha
    txa
    ldx #1
    jsr leftpad
    pla
    jsr writeByte
    rts
.endproc
