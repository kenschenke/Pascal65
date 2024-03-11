.include "runtime.inc"

.export getScreenSize

.import is80Cols, is50Rows, storeVarParam

.proc getScreenSize
    lda #0
    sta sreg
    sta sreg + 1
    tax
    jsr is80Cols
    cmp #0
    bne C8
    lda #40
    bne SC
C8: lda #80
SC: ldy #0
    jsr storeVarParam
    ldx #0
    jsr is50Rows
    cmp #0
    bne R5
    lda #25
    bne SR
R5: lda #50
SR: ldy #1
    jmp storeVarParam
.endproc
