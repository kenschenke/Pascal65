.include "runtime.inc"
.include "cbm_kernal.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp writeBool

; end of exports
.byte $00, $00, $00

; imports

leftpad: jmp $0000
printz: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

.data

TRUE:  .asciiz "true"
FALSE: .asciiz "false"

.code

; Write boolean TRUE or FALSE to output.
; Boolean value in .A
; Field width in .X
.proc writeBool
    stx tmp1            ; field width in tmp1
    ldx #5              ; start with value width of 5
    cmp #0              ; is boolean value false?
    beq L1              ; if so, skip the next instruction
    dex                 ; value is true, so value width is 4
L1:
    pha                 ; save boolean on the CPU stack
    lda tmp1            ; load field width into A
    jsr leftpad         ; left pad
    pla                 ; pop boolean value off CPU stack
    bne L2              ; if value is true, skip ahead
    ldx #0
:   lda FALSE,x
    beq L3
    jsr CHROUT
    inx
    bne :-
L2:
    ldx #0
:   lda TRUE,x
    beq L3
    jsr CHROUT
    inx
    bne :-
L3:
    rts
.endproc
