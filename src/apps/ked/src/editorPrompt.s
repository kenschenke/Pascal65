.include "cbm_kernal.inc"

.export _editorPrompt

.import _printz, getlineNoEnter, inputBuf, inputBufUsed, popax
.importzp ptr1, tmp1

; Returns 0 if STOP was pressed
; char editorPrompt(char *buf, size_t bufsize, char *prompt)
.proc _editorPrompt
    pha
    txa
    pha
    ldy #0                  ; column
    ldx #24                 ; row
    clc
    jsr PLOT
    lda #5
    jsr CHROUT              ; Set text color to white
    pla
    tax
    pla
    jsr _printz
    jsr getlineNoEnter
    cmp #0
    beq L1
    lda #0
    ldx #0
    rts
L1:
    jsr popax
    pha
    jsr popax
    sta ptr1
    stx ptr1 + 1
    pla
    sta tmp1
    dec tmp1                ; Allow space for zero-terminator
    ldx #0
    ldy #0
L2:
    lda tmp1
    beq L3
    lda inputBufUsed
    beq L3
    lda inputBuf,x
    sta (ptr1),y
    inx
    iny
    dec inputBufUsed
    dec tmp1
    jmp L2
L3:
    lda #0
    sta (ptr1),y
    lda #1
    ldx #0
    rts
.endproc
