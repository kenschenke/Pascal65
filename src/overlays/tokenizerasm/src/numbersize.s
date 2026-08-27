.include "tokenizer.inc"
.include "zeropage.inc"
.include "asmlib.inc"

.export numberSize

.import tokenizerCode

; This routine determines the size of the number literal in intOp1/intOp2.
; It sets tokenizerCode to tzByte, tzWord, or tzCardinal.
.proc numberSize
    ; Is the number an unsigned short (1 byte)?
    lda #$ff
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    jsr leUint32
    cmp #0
    beq L1
    lda #tzByte
    sta tokenizerCode
    rts

L1: ; Is the number an unsigned integer (2 bytes)?
    lda #$ff
    sta intOp32+1
    jsr leUint32
    cmp #0
    beq L2
    lda #tzWord
    sta tokenizerCode
    rts

L2: lda #tzCardinal
    sta tokenizerCode
    rts
.endproc
