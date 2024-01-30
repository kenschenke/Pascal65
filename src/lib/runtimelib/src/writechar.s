.include "cbm_kernal.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp writeChar

; end of exports
.byte $00, $00, $00

; imports

leftpad: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

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
