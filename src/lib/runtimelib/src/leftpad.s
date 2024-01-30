.include "cbm_kernal.inc"
.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp leftpad

; end of exports
.byte $00, $00, $00

; imports

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

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
    jsr CHROUT
    clc
    bcc Loop

Done:
    rts
.endproc
