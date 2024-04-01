;
; fileio.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

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

; New FH in A
; Previous FH returned in A
.proc setFh
    ldx currentFh
    stx tmp1
    sta currentFh
    cmp #fhString
    beq DN
    cmp #fhStdio
    bne :+
    jsr CLRCHN
    jmp DN
:   tax
    lda files,x
    bne :+
    lda #rteInvalidFileHandle
    jmp runtimeError
:   jsr CHKOUT
DN: lda tmp1
    rts
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
