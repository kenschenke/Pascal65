; C / ASM glue code for int16

.export _formatInt16, _leftPad, _printInt16

.import intBuf, intOp1, writeInt16, _printz, popa, leftpad

; const char *formatInt16(int num)
.proc _formatInt16
    sta intOp1
    stx intOp1 + 1
    lda #0
    jsr writeInt16
    lda #<intBuf
    ldx #>intBuf
    rts
.endproc

; void leftPad(char fieldWidth, char valueWidth)
.proc _leftPad
    tax
    jsr popa
    jmp leftpad
.endproc

; void printInt16(int num)
.proc _printInt16
    sta intOp1
    stx intOp1 + 1
    jsr writeInt16
    lda #<intBuf
    ldx #>intBuf
    jmp _printz
.endproc
