.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp popax
jmp popa

; end of exports
.byte $00, $00, $00

; imports

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

.proc popax
    ldy #1
    lda (sp),y
    tax
    dey
    lda (sp),y
    inc sp
    beq L1
    inc sp
    beq L2
    rts
L1:
    inc sp
L2:
    inc sp + 1
    rts
.endproc

.proc popa
    ldy #0
    lda (sp),y
    inc sp
    beq @L1
    rts
@L1:
    inc sp+1
    rts
.endproc
