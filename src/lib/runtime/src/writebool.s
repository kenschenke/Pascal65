.ifdef RUNTIME
.include "runtime.inc"
.else
.importzp tmp1
.endif

.import leftpad, printz
.export writeBool

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
    lda #<FALSE
    ldx #>FALSE
    jmp printz
L2:
    lda #<TRUE
    ldx #>TRUE
    jmp printz
.endproc
