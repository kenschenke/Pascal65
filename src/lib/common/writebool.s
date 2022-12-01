.include "cbm_kernal.inc"

.import leftpad
.importzp tmp1, tmp2, ptr1
.export writeBool

.data

TRUE:  .asciiz "TRUE"
FALSE: .asciiz "FALSE"

.code

; Write boolean TRUE or FALSE to output.
; Boolean value in .A
; Field width in .X
.proc writeBool
    sta tmp1
    stx tmp2
    ldx #5
    cmp #0
    beq L1
    dex
L1:
    lda tmp1
    pha
    lda tmp2
    jsr leftpad
    lda #<FALSE
    sta ptr1
    lda #>FALSE
    sta ptr1 + 1
    ldy #0
    pla
    cmp #0
    beq L2
    lda #<TRUE
    sta ptr1
    lda #>TRUE
    sta ptr1 + 1
L2:
    lda (ptr1),y
    beq L3
    jsr CHROUT
    iny
    jmp L2
L3:
    rts

.endproc
