;
; writetostring.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;

; These routines write to a string.
;
; They use the input buffer as temporary storage and when it
; overflows, a string is allocated and the buffer is reset
; then later appended to the string.

.include "runtime.inc"
.include "inputbuf.inc"

.export resetStringBuffer, addToStringBuffer, getStringBuffer

bufIndex: .res 1
strPtr: .res 2
srcIndex: .res 1
srcLength: .res 1
destIndex: .res 1

.proc resetStringBuffer
    lda #0
    sta bufIndex
    sta strPtr
    sta strPtr + 1
    sta destIndex
    rts
.endproc

; This routine adds to the string buffer.
; Source passed in A/X
; Length in Y
.proc addToStringBuffer
    cpy #0
    beq DN
    sta ptr1
    stx ptr1 + 1
    sty srcLength
    lda #0
    sta srcIndex
LP: ldx bufIndex
    cpx #INPUTBUFLEN
    bne L1
    lda ptr1
    pha
    lda ptr1 + 1
    pha
    lda srcIndex
    pha
    jsr flushStringBuffer
    pla
    sta srcIndex
    pla
    sta ptr1 + 1
    pla
    sta ptr1
L1: ldy srcIndex
    lda (ptr1),y
    ldy bufIndex
    sta (inputBuf),y
    inc srcIndex
    inc bufIndex
    dec srcLength
    bne LP
DN: rts
.endproc

; This routine copies the existing string to a new string object.
; It is called from flushStringBuffer.
; On exit, Y contains the last-written index.
.proc copyStringBuffer
    lda strPtr
    sta ptr1
    lda strPtr + 1
    sta ptr1 + 1
    ldy #0
    lda (ptr1),y
    pha
    clc
    adc bufIndex
    pha
    adc #1
    ldx #0
    jsr rtHeapAlloc
    sta ptr2
    stx ptr2 + 1
    pla
    ldy #0
    sta (ptr2),y
    ; Copy the old string to the new one
    pla
    tax
    lda strPtr
    sta ptr1
    lda strPtr + 1
    sta ptr1 + 1
:   iny
    lda (ptr1),y
    sta (ptr2),y
    dex
    bne :-
    ; Free the original string
    lda ptr2
    pha
    lda ptr2 + 1
    pha
    tya
    pha
    lda strPtr
    ldx strPtr + 1
    jsr rtHeapFree
    ; Store the new string pointer
    pla
    tay
    pla
    sta strPtr + 1
    sta ptr2 + 1
    pla
    sta strPtr
    sta ptr2
    rts
.endproc

; This routine copies the characters in the string buffer
; into a string object. It is called when the string buffer
; fills up and more characters need to be written.
;
; It first looks to see if an existing string exists in strPtr.
; If so, it includes its contents in the new string.
.proc flushStringBuffer
    ; Is there an existing string object?
    lda strPtr
    ora strPtr + 1
    beq NS
    ; A string object already exists.
    jsr copyStringBuffer
    sty destIndex               ; Y still contains the index
    inc destIndex
    jmp CP
NS: lda bufIndex
    pha
    clc
    adc #1
    ldx #0
    jsr rtHeapAlloc
    sta strPtr
    sta ptr2
    stx strPtr + 1
    stx ptr2 + 1
    ldy #0
    pla
    sta (ptr2),y
    iny
    sty destIndex
CP: lda #0
    sta srcIndex
    ldx bufIndex
:   ldy srcIndex
    lda (inputBuf),y
    ldy destIndex
    sta (ptr2),y
    inc srcIndex
    inc destIndex
    dex
    bne :-
    lda #0
    sta bufIndex
    rts
.endproc

; This routine allocates a string object from the input buffer
; as well as any existing string from input buffer overflows.
; The string is returned in A/X and the current buffer and
; string pointers are reset.
.proc getStringBuffer
    jsr flushStringBuffer
    lda strPtr
    pha
    lda strPtr + 1
    pha
    jsr resetStringBuffer
    pla
    tax
    pla
    rts
.endproc
