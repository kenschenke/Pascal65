; Dump memory heap allocation table (MAT)

.include "cbm_kernal.inc"

.import heapTop, writeInt16, _printz, intOp1, intBuf
.importzp ptr1, ptr2

.export dumpMAT, dumpHexByte

.data

hexStr: .asciiz "0123456789abcdef"
strValFree: .asciiz "free: "
strValYes: .asciiz "yes"
strValNo: .asciiz "no"

.bss

heapPtr: .res 2
heapIndex: .res 1

.code

; Dumps lower 4 bits of A
.proc dumpHexNibble
    tay
    lda #<hexStr
    sta ptr2
    lda #>hexStr
    sta ptr2 + 1
    lda (ptr2),y
    jsr CHROUT
    rts
.endproc

; Outputs an 8-bit number in hexadecimal
; Number passed in A
.proc dumpHexByte
    pha         ; Save the number
    lsr
    lsr
    lsr
    lsr
    jsr dumpHexNibble
    pla
    and #$0f
    jmp dumpHexNibble
.endproc

.proc dumpIndex
    lda heapIndex
    sta intOp1
    lda #0
    sta intOp1 + 1
    lda #2
    jsr writeInt16
    lda #<intBuf
    ldx #>intBuf
    jsr _printz
    ; Print separators
    lda #':'
    jsr CHROUT
    lda #' '
    jsr CHROUT
    rts
.endproc

.proc dumpSize
    lda heapPtr
    sta ptr1
    lda heapPtr + 1
    sta ptr1 + 1
    ldy #0
    lda (ptr1),y
    sta intOp1
    iny
    lda (ptr1),y
    and #$7f
    sta intOp1 + 1
    lda #4
    jsr writeInt16
    lda #<intBuf
    ldx #>intBuf
    jsr _printz
    ; Print separator
    lda #' '
    jsr CHROUT
    jsr CHROUT
    rts
.endproc

.proc dumpPointer
    lda heapPtr
    sta ptr1
    lda heapPtr + 1
    sta ptr1 + 1
    ldy #3
    lda (ptr1),y
    jsr dumpHexByte
    ldy #2
    lda (ptr1),y
    jsr dumpHexByte
    ; Print separator
    lda #' '
    jsr CHROUT
    jsr CHROUT
    rts
.endproc

.proc dumpFree
    lda #<strValFree
    ldx #>strValFree
    jsr _printz
    lda heapPtr
    sta ptr1
    lda heapPtr + 1
    sta ptr1 + 1
    ldy #1
    lda (ptr1),y
    and #$80
    beq L3
    lda #<strValNo
    ldx #>strValNo
    jmp L4
L3:
    lda #<strValYes
    ldx #>strValYes
L4:
    jsr _printz
    lda #13
    jsr CHROUT
    rts
.endproc

.proc dumpMAT
    lda heapTop
    sta heapPtr
    lda heapTop + 1
    sta heapPtr + 1
    lda #1
    sta heapIndex
L1:
    lda heapPtr
    sta ptr1
    lda heapPtr + 1
    sta ptr1 + 1
    ldy #3
L11:
    lda (ptr1),y
    bne L2
    dey
    bpl L11
    jmp L99
L2:
    ; Print entry number (heapIndex)
    jsr dumpIndex
    ; Print size
    jsr dumpSize
    ; Print pointer
    jsr dumpPointer
    ; Free
    jsr dumpFree
    ; Inc
    inc heapIndex
    lda heapPtr
    sec
    sbc #4
    sta heapPtr
    lda heapPtr + 1
    sbc #0
    sta heapPtr + 1
    jmp L1
L99:
    rts
.endproc
