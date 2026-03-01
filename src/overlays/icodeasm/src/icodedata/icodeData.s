.include "asmlib.inc"
.include "icode.inc"
.include "zeropage.inc"
.include "membufasm.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export icodeInitData, icodeSaveData, icodeWriteData, icodeFreeData

.import icodeLabel

.bss

dataMemBuf: .res 4
callerMemBuf: .res 4
buffer: .res 1
buflen: .res 2

.code

.proc icodeInitData
    lda #0
    tax
    tay
    taz
    stq dataMemBuf
    rts
.endproc

; This routine saves a block to the intermediate code's data segment.
; Information in the block is saved until everything in the code segment
; is written. The data segment is then written at the end.
;
; The label in icodeLabel is used as the label for this block of data.
; Q contains a pointer an allocated memory buffer.
.proc icodeSaveData
    jsr pushQ           ; save the caller's membuf

    ldq dataMemBuf
    jsr isQZero
    bne :+
    jsr allocMemBuf
    stq dataMemBuf

    ; Write the caller's membuf pointer
:   jsr popQ
    stq callerMemBuf
    lda #<callerMemBuf
    sta ptr2
    lda #>callerMemBuf
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    ldq dataMemBuf
    stq ptr1
    lda #4
    ldx #0
    jsr writeToMemBuf

    ; Write the label
    ldq dataMemBuf
    stq ptr1
    lda #<icodeLabel
    sta ptr2
    lda #>icodeLabel
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    tax
    ; Count the label length
:   lda icodeLabel,x
    beq :+
    inx
    bne :-
:   inx
    txa
    ldx #0
    jsr writeToMemBuf

    rts
.endproc

; This routine writes the data segments to the intermediate code.
.proc icodeWriteData
    ldq dataMemBuf
    jsr isQZero
    bne :+
    rts

:   stq ptr1
    lda #0
    tax
    jsr setMemBufPos

    ; Loop through the membuf
L1: ldq dataMemBuf
    jsr isMemBufAtEnd
    bne :+
    rts

:   ldq dataMemBuf
    stq ptr1
    lda #<callerMemBuf
    sta ptr2
    lda #>callerMemBuf
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #4
    ldx #0
    jsr readFromMemBuf

    ; Write the mnemonic for the data segment
    lda #IC_DAT
    jsr CHROUT

    ; Write the label
    lda #IC_LBL
    jsr CHROUT
L2: ldq dataMemBuf
    stq ptr1
    lda #<buffer
    sta ptr2
    lda #>buffer
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #1
    ldx #0
    jsr readFromMemBuf
    lda buffer
    jsr CHROUT
    lda buffer
    bne L2

    ; Look up the length of the data membuf
    ldq callerMemBuf
    stq ptr1
    ldz #MEMBUF::used
    nop
    lda (ptr1),z
    sta buflen
    inz
    nop
    lda (ptr1),z
    sta buflen+1

    ; Write the membuf length
    lda #IC_IWU
    jsr CHROUT
    lda buflen
    jsr CHROUT
    lda buflen+1
    jsr CHROUT

    ; Rewind the membuf
    ldq callerMemBuf
    stq ptr1
    lda #0
    tax
    jsr setMemBufPos

    ; Write the membuf
L3: lda buflen
    ora buflen+1
    beq L4
    ldq callerMemBuf
    stq ptr1
    lda #<buffer
    sta ptr2
    lda #>buffer
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #1
    ldx #0
    jsr readFromMemBuf
    lda buffer
    jsr CHROUT
    lda buflen
    sec
    sbc #1
    sta buflen
    lda buflen+1
    sbc #0
    sta buflen+1
    bra L3
L4: jmp L1
.endproc

; This routine frees the icode data segment and all membufs inside it.
.proc icodeFreeData
    ldq dataMemBuf
    jsr isQZero
    bne :+
    rts

    ; Rewind the membuf
:   stq ptr1
    lda #0
    tax
    jsr setMemBufPos

    ; Loop through the membufs inside
L1: ldq dataMemBuf
    jsr isMemBufAtEnd
    bne :+
    jmp DN

    ; Read the membuf
:   ldq dataMemBuf
    stq ptr1
    lda #<callerMemBuf
    sta ptr2
    lda #>callerMemBuf
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #4
    ldx #0
    jsr readFromMemBuf

    ldq callerMemBuf
    jsr freeMemBuf

    ; Read past the label
L2: ldq dataMemBuf
    stq ptr1
    lda #<buffer
    sta ptr2
    lda #>buffer
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #1
    ldx #0
    jsr readFromMemBuf
    lda buffer
    bne L2

    ; Loop back to read the next segment
    bra L1

DN: ldq dataMemBuf
    jsr freeMemBuf
    lda #0
    tax
    tay
    taz
    stq dataMemBuf
    rts
.endproc
