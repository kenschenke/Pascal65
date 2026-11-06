;
; strinput.s
; Ken Schenke (kenschenke@gmail.com)
;
; Read a string from input
;
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;

.include "types.inc"
.include "runtime.inc"
.include "error.inc"
.include "cbm_kernal.inc"
.include "inputbuf.inc"

.export readStringFromInput, setStringInput

.import skipSpaces, setFh

.bss

strPtr: .res 2
strLen: .res 1
destIndex: .res 1

.code

; This routine reads a string of characters from the input
; and stores them in a string variable.  It skips spaces in
; the input until the first non-space. The rest of the input
; buffer is read into the string.
;
; Inputs
;   A/X - pointer to string variable address on runtime stack
.proc readStringFromInput
    sta strPtr
    sta ptr1
    stx strPtr + 1
    stx ptr1 + 1
    ; Free existing heap for string
    ldy #1
    lda (ptr1),y
    tax
    dey
    lda (ptr1),y
    jsr rtHeapFree
    jsr skipSpaces          ; Skip over spaces in the input buffer
    ; Calculate length of input
    lda #0
    sta strLen
    lda inputPos
    cmp inputBufUsed
    bcs :+                  ; Branch if no input is left
    lda inputBufUsed
    sec
    sbc inputPos
    sta strLen
:   lda strLen
    clc
    adc #1                  ; Add 1 for string length
    ldx #0
    jsr rtHeapAlloc
    sta ptr2
    stx ptr2 + 1
    ldy #0
    lda strLen
    sta (ptr2),y
    ; Copy the input from inputPos to the string
    lda #1
    sta destIndex
    ldx strLen
    beq L2
L1: ldy inputPos
    lda (inputBuf),y
    ldy destIndex
    sta (ptr2),y
    inc destIndex
    inc inputPos
    dex
    bne L1
L2: lda strPtr
    sta ptr1
    lda strPtr + 1
    sta ptr1 + 1
    ldy #0
    lda ptr2
    sta (ptr1),y
    iny
    lda ptr2 + 1
    sta (ptr1),y
    rts
.endproc

; This routine starts ReadStr. It copies a string object into the
; input buffer, frees the string object and sets the current input
; to fhString. The reads that follow take their input from the buffer.
; A string longer than the input buffer is truncated.
;
; Inputs
;   A/X - pointer to a string object
.proc setStringInput
    sta strPtr
    sta ptr1
    stx strPtr + 1
    stx ptr1 + 1
    ; Clear the buffer, as getline does. Number input stops at the
    ; first non-digit, not at the end of the input.
    lda #0
    ldy #INPUTBUFLEN - 1
:   sta (inputBuf),y
    dey
    bpl :-
    ldy #0
    lda (ptr1),y            ; String length
    cmp #INPUTBUFLEN
    bcc :+
    lda #INPUTBUFLEN
:   sta inputBufUsed
    sta strLen
    lda #0
    sta inputPos
    ; Copy the characters. Source index is one more than the destination.
    ldx strLen
    beq L2
    ldy #1
L1: lda (ptr1),y
    dey
    sta (inputBuf),y
    iny
    iny
    dex
    bne L1
L2: lda strPtr
    ldx strPtr + 1
    jsr rtHeapFree
    lda #fhString
    ldx #1                  ; Input
    jmp setFh
.endproc
