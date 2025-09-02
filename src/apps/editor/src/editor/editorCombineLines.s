;
; editorCombineLines.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; editorCombineLines routine

.include "zeropage.inc"
.include "editor.inc"
.include "4510macros.inc"
.include "asmlib.inc"

.export editorCombineLines

.import editorRowAt, editorSetAllRowsDirty, editorFreeLine
.import currentEditorRow, renderCursor

.bss

prevLine: .res 4
currentLine: .res 4
prevLength: .res 1
combinedLength: .res 1
newBuffer: .res 4

.code

; This routine is called to combine the current line with the 
; previous one. If the previous line is not long enough, its buffer
; is re-allocated. Once the characters from the current line are copied,
; is is deleted from the file.
.proc editorCombineLines
    ; Find the previous line
    ldz #EDITFILE::cy
    nop
    lda (currentFile),z
    sta tmp1                ; Put current line in tmp1/tmp2
    inz
    nop
    lda (currentFile),z
    sta tmp2
    dew tmp1                ; Decrement current line by one
    lda tmp1
    ldx tmp2
    jsr editorRowAt         ; Previous line in ptr2
    ldq ptr2
    stq prevLine
    ldz #EDITLINE::capacity
    nop
    lda (ptr2),z
    pha                     ; Push the previous line's capacity to the stack
    ldz #EDITLINE::length
    nop
    lda (ptr2),z
    sta prevLength
    jsr currentEditorRow    ; Current row in ptr2
    ldq ptr2
    stq currentLine
    ldz #EDITLINE::length
    nop
    lda (ptr2),z            ; Current row length
    clc
    adc prevLength          ; Add length of previous row
    sta combinedLength      ; Combined length in tmp2
    pla                     ; Pop the previous line's capacity from the stack
    cmp combinedLength      ; Is previous row capacity > combined length?
    bcs L1                  ; Branch if combined length <= previous row capacity
    ; The combined row length will not fit in the previous row's existing buffer.
    ; A new buffer needs to be allocated.
    lda combinedLength
    ldx #0
    jsr heapAlloc           ; Allocate a big enough buffer for the combined row
    stq ptr4                ; New buffer in ptr4
    stq newBuffer
    ldq prevLine
    stq ptr2                ; Previous row in ptr2
    ldz #EDITLINE::buffer
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr3                ; Previous row's buffer in ptr3
    ldz #EDITLINE::length
    nop
    lda (ptr2),z
    taz
    ; Copy characters from previous line into new buffer
:   dez
    bmi :+
    nop
    lda (ptr3),z
    nop
    sta (ptr4),z
    bne :-
:   ldz #EDITLINE::capacity
    lda combinedLength
    nop
    sta (ptr2),z            ; Set capacity to combined length
    ; Free the old buffer
    ldq ptr3
    jsr heapFree
    ; Set the previous line to the new buffer
    ldq prevLine
    stq ptr3
    ldz #EDITLINE::buffer+3
    ldx #3
:   lda newBuffer,x
    nop
    sta (ptr3),z
    dez
    dex
    bpl :-
L1: ldq currentLine
    stq ptr2
    ldz #EDITLINE::buffer
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr3                ; Current row's buffer in ptr3
    ldq prevLine
    stq ptr2
    ldz #EDITLINE::buffer
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr4                ; Previous rows's buffer in ptr4
    lda prevLength
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq ptr4
    clc
    adcq intOp32
    stq ptr4                ; Add previous row's length to its buffer pointer
    ; Copy characters from current row and append to buffer in ptr4
    ldq currentLine
    stq ptr2
    ldz #EDITLINE::length
    nop
    lda (ptr2),z
    sta tmp3
    ldz #0
:   dec tmp3
    bmi :+
    nop
    lda (ptr3),z
    nop
    sta (ptr4),z
    inz
    bne :-
:   ; Set new length of the previous row
    ldq prevLine
    stq ptr2
    ldz #EDITLINE::length
    lda combinedLength
    nop
    sta (ptr2),z
    ; Delete the current row
    ldq currentLine
    stq ptr2
    stq ptr4                ; Store current line pointer in ptr4
    ldz #EDITLINE::next
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr3                ; "next" pointer for current row in ptr3
    ldq prevLine
    stq ptr2
    ldz #EDITLINE::next+3
    ldx #3
:   lda ptr3,x
    nop
    sta (ptr2),z
    dez
    dex
    bpl :-
    ldq ptr4
    jsr editorFreeLine
    ; Decrement line count by 1
    ldz #EDITFILE::numLines
    nop
    lda (currentFile),z
    sta tmp1
    inz
    nop
    lda (currentFile),z
    sta tmp2
    dew tmp1
    ldz #EDITFILE::numLines
    lda tmp1
    nop
    sta (currentFile),z
    inz
    lda tmp2
    nop
    sta (currentFile),z
    ; Move the cursor up one line
    clc
    jsr renderCursor
    ldz #EDITFILE::cy
    nop
    lda (currentFile),z
    sta tmp1
    inz
    nop
    lda (currentFile),z
    sta tmp2
    dew tmp1
    lda tmp2
    nop
    sta (currentFile),z
    dez
    lda tmp1
    nop
    sta (currentFile),z
    ; Move the cursor to the new position
    ldz #EDITFILE::cx
    lda prevLength
    nop
    sta (currentFile),z
    jsr editorSetAllRowsDirty
    rts
.endproc

