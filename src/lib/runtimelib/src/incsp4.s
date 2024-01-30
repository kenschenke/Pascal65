.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp incsp4

; end of exports
.byte $00, $00, $00

; imports

addysp: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

.proc incsp4
    ldy #4
    jmp addysp
.endproc
