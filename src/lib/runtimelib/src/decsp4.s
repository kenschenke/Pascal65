.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp decsp4

; end of exports
.byte $00, $00, $00

; imports

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

.proc decsp4
    lda sp
    sec
    sbc #4
    sta sp
    bcc @L1
    rts
@L1:
    dec sp + 1
    rts
.endproc
