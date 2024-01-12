.include "runtime.inc"
.include "cbm_kernal.inc"

.export dumpHeap

.import printz, printlnz, heapTop, heapBottom

.data

digits: .asciiz "0123456789abcdef"
base: .asciiz "Heap Base: $"
hdr1: .asciiz "Length  Pointer  Allocated"
hdr2: .asciiz "------  -------  ---------"
yes: .asciiz "   Y"
no: .asciiz "   N"

.code

; Prints the hex number in A
.proc dumpByte
    pha
    lsr
    lsr
    lsr
    lsr
    ldx #<digits
    stx ptr1
    ldx #>digits
    stx ptr1 + 1
    and #$0f
    tay
    lda (ptr1),y
    jsr CHROUT
    pla
    and #$0f
    tay
    lda (ptr1),y
    jmp CHROUT
.endproc

.proc dumpEntry
    ; Length
    lda #'$'
    jsr CHROUT
    ldy #1
    lda (ptr3),y
    and #$7f
    jsr dumpByte
    ldy #0
    lda (ptr3),y
    jsr dumpByte

    ; Pointer
    lda #' '
    ldx #3
:   jsr CHROUT
    dex
    bpl :-
    lda #'$'
    jsr CHROUT
    ldy #3
    lda (ptr3),y
    jsr dumpByte
    ldy #2
    lda (ptr3),y
    jsr dumpByte

    ; Allocated
    lda #' '
    ldx #3
:   jsr CHROUT
    dex
    bpl :-
    ldy #1
    lda (ptr3),y
    and #$80
    bne :+
    lda #<no
    ldx #>no
    jmp printlnz
:   lda #<yes
    ldx #>yes
    jmp printlnz
.endproc

; Dumps the MAT (memory allocation table)
.proc dumpHeap
    lda #<base
    ldx #>base
    jsr printz
    lda heapBottom + 1
    jsr dumpByte
    lda heapBottom
    jsr dumpByte
    lda #13
    jsr CHROUT

    lda #<hdr1
    ldx #>hdr1
    jsr printlnz
    lda #<hdr2
    ldx #>hdr2
    jsr printlnz

    ; Current MAT position in ptr3
    lda heapTop
    sta ptr3
    lda heapTop + 1
    sta ptr3 + 1

L1:
    ldy #0
    ldx #3
:   lda (ptr3),y
    bne L2
    iny
    dex
    bpl :-
    jmp Done

L2:
    jsr dumpEntry

    lda ptr3
    sec
    sbc #4
    sta ptr3
    lda ptr3 + 1
    sbc #0
    sta ptr3 + 1

    jmp L1

Done:
    lda #13
    jsr CHROUT
    rts
.endproc
