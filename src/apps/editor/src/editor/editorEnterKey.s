;
; editorEnterKey.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; editorEnterKey routine

.include "editor.inc"
.include "zeropage.inc"
.include "4510macros.inc"
.include "asmlib.inc"

.export editorEnterKey

.import currentEditorRow, renderCursor, anyDirtyRows, screenrows, isQZero
.import editorInsertLine

.proc editorEnterKey
    ; ptr2 - current line
    ; ptr1 - new line
    jsr editorInsertLine

    ; If ptr2 is NULL then skip to marking rows dirty
    ldq ptr2
    jsr isQZero
    bne :+
    jmp DN

    ; Is the current line empty?
:   ldz #EDITLINE::buffer
    neg
    neg
    nop
    lda (ptr2),z
    jsr isQZero
    bne :+                  ; Branch if current line isn't empty
    jmp MD
:   ldz #EDITLINE::length
    nop
    lda (ptr2),z
    bne :+                  ; Branch if length is not zero
    jmp MD                  ; Nothing else to do

    ; Save ptr1 on the CPU stack
:   ldq ptr1
    pha
    phx
    phy
    phz

    ; Truncate the current line and copy characters to new line
    ldz #EDITFILE::cx
    nop
    lda (currentFile),z     ; Get cursor position
    sta tmp1                ; Put it in tmp1
    ldz #EDITLINE::length
    nop
    lda (ptr2),z            ; Get length of current line
    sec
    sbc tmp1                ; Subtract the cursor position
    pha                     ; Save the new line length on the CPU stack
    ldx #0
    jsr heapAlloc           ; Allocate a buffer for the remaining characters
    stq ptr4
    jsr currentEditorRow    ; Get the current row back into ptr2
    pla
    sta tmp1                ; New line length
    ; Pop ptr1 back off the CPU stack
    plz
    ply
    plx
    pla
    stq ptr1
    ; Save the newly allocated line buffer into the new line
    ldz #EDITLINE::buffer+3
    ldx #3
:   lda ptr4,x
    nop
    sta (ptr1),z
    dez
    dex
    bpl :-
    ldz #EDITLINE::capacity
    lda tmp1
    nop
    sta (ptr1),z
    ldz #EDITLINE::length
    nop
    sta (ptr1),z
    ; Put the current line length in intOp32
    ldz #EDITFILE::cx
    nop
    lda (currentFile),z
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ; Put current line's buffer in ptr3
    ldz #EDITLINE::buffer
    neg
    neg
    nop
    lda (ptr2),z
    ; Add new line length to ptr3
    clc
    adcq intOp32
    stq ptr3
    ; Copy the characters from ptr3 to ptr4
    ldz #0
:   nop
    lda (ptr3),z
    nop
    sta (ptr4),z
    inz
    dec tmp1
    bne :-
    ; Set the current line's new length
    ldz #EDITFILE::cx
    nop
    lda (currentFile),z
    ldz #EDITLINE::length
    nop
    sta (ptr2),z
    ; Mark all rows dirty, starting at the current row and continuing
    ; through the visible rows
MD: ldz #EDITFILE::cy
    nop
    lda (currentFile),z
    sta intOp1
    inz
    nop
    lda (currentFile),z
    sta intOp1+1
    ldz #EDITFILE::rowOff
    nop
    lda (currentFile),z
    sta intOp2
    inz
    nop
    lda (currentFile),z
    sta intOp2+1
    jsr subInt16                ; intOp1 now contains screen row number
:   ldz #EDITLINE::dirty
    lda #1
    nop
    sta (ptr2),z
    ; Get pointer for next line
    ldz #EDITLINE::next
    neg
    neg
    nop
    lda (ptr2),z
    jsr isQZero
    beq :+                      ; Branch if next line is null
    stq ptr2
    inc intOp1
    lda intOp1
    cmp screenrows
    bcc :-
:   lda #1
    sta anyDirtyRows

DN: clc
    jsr renderCursor
    ; Move the cursor down a line and into the first column
    ldz #EDITFILE::cy
    nop
    lda (currentFile),z
    clc
    adc #1
    nop
    sta (currentFile),z
    bcc :+
    inz
    nop
    lda (currentFile),z
    adc #0
    nop
    sta (currentFile),z
:   ldz #EDITFILE::cx
    lda #0
    nop
    sta (currentFile),z
    ; Increment the number of lines in the file
    ldz #EDITFILE::numLines
    nop
    lda (currentFile),z
    clc
    adc #1
    nop
    sta (currentFile),z
    bcc :+
    inz
    nop
    lda (currentFile),z
    adc #0
    nop
    sta (currentFile),z
:   rts
.endproc

