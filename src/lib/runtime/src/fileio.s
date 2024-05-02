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
.export createFh, freeFh

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

; Return an unused file handle in A (1-10)
; If no available file handles, runtime error thrown
.proc createFh
    ldx #0
L1: cpx #maxFiles
    beq ER
    lda files,x
    beq DN
    inx
    jmp L1
ER: lda #rteInvalidFileHandle
    jmp runtimeError
DN: lda #1
    sta files,x
    inx
    txa
    rts
.endproc

; Frees the file handle in A (1-10)
; If file handle is not being used, runtime error thrown
.proc freeFh
    tax
    dex
    lda files,x
    beq ER
    lda #0
    sta files,x
    rts
ER: lda #rteInvalidFileHandle
    jmp runtimeError
.endproc

; New FH in A
; Previous FH returned in A
.proc setFh
    ldx currentFh               ; Load the previous FH
    stx tmp1                    ; Store it in tmp1 for a bit
    sta currentFh               ; Set the current FH
    cmp #fhString               ; Is the new FH a string output?
    beq DN                      ; Branch if it is
    cmp #fhStdio                ; Is the new FH stdout?
    bne :+                      ; Skip ahead if it isn't
    jsr CLRCHN                  ; The new FH is stdout - set kernal output to screen
    jmp DN                      ; Done
:   tax                         ; Put new FH in X
    dex                         ; Decrement by 1 (since filehandles are 1-based)
    lda files,x                 ; Check if new FH is allocated
    bne :+                      ; Skip ahead if it is
    lda #rteInvalidFileHandle   ; Invalid filehandle
    jmp runtimeError
:   jsr CHKOUT                  ; Set the kernal to the new FH
DN: lda tmp1                    ; Load the previous FH
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
