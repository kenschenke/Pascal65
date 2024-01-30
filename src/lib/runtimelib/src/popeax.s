.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp popeax

; end of exports
.byte $00, $00, $00

; imports

incsp4: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

.proc popeax
    ldy #3
    lda (sp),y
    sta sreg + 1
    dey
    lda (sp),y
    sta sreg
    dey
    lda (sp),y
    tax
    dey
    lda (sp),y
    jmp incsp4
.endproc
