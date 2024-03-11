; File I/O

.include "runtime.inc"
.include "cbm_kernal.inc"
.include "error.inc"

maxFiles = 10

.export initFileIo, setFh, currentFh, writeByte, writeData

.import runtimeError, addToStringBuffer

currentFh: .res 1
files: .res maxFiles
buffer: .res 1

.proc initFileIo
    lda #fhStdio
    sta currentFh
    ldx #maxFiles - 1
    lda #0
:   sta files,x
    dex
    bpl :-
    rts
.endproc

.proc setFh
    sta currentFh
    cmp #fhString
    beq DN
    cmp #fhStdio
    bne :+
    jmp CLRCHN
:   tax
    lda files,x
    bne :+
    lda #rteInvalidFileHandle
    jmp runtimeError
:   jmp CHKOUT
DN: rts
.endproc

; This routine writes one byte to the current output.
; The contents of A/X/Y are preserved.
;
; Byte in A
.proc writeByte
    sta buffer
    pha
    txa
    pha
    tya
    pha
    ldx currentFh
    cpx #fhString
    beq :+
    pla
    tay
    pla
    tax
    pla
    jmp CHROUT
:   lda #<buffer
    ldx #>buffer
    ldy #1
    jsr addToStringBuffer
    pla
    tay
    pla
    tax
    pla
    rts
.endproc

; This routine writes data to the current output.
;
; Pointer to data to A/X
; Length in Y
.proc writeData
    pha
    lda currentFh
    cmp #fhString
    bne :+
    pla
    jmp addToStringBuffer
:   pla
    sta ptr1
    stx ptr1 + 1
    tya
    tax
    ldy #0
:   lda (ptr1),y
    jsr CHROUT
    iny
    dex
    bpl :-
    rts
.endproc