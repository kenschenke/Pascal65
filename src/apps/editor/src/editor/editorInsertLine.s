;
; editorInsertLine.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; editorInsertLine routine

.include "editor.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export editorInsertLine

.import editorAllocLine, currentEditorRow, closeGapBuf, isQZero

; This routine inserts a new line after the current line
; On exit:
;    ptr1 - new line
;    ptr2 - current line
.proc editorInsertLine
    jsr editorAllocLine     ; Allocate a new line in ptr1
    
    ; Special case: cursor is in first column of first row.
    ldz #EDITFILE::cx
    nop
    lda (currentFile),z
    bne L0
    ldz #EDITFILE::cy
    nop
    lda (currentFile),z
    bne L0
    inz
    nop
    lda (currentFile),z
    bne L0
    ; Insert the new row as the first row
    ldz #EDITFILE::firstLine
    neg
    neg
    nop
    lda (currentFile),z
    stq ptr2                ; Copy current firstLine into ptr2
    ldz #EDITLINE::next+3
    ldx #3
:   lda ptr2,x
    nop
    sta (ptr1),z            ; Store current firstLine as nextLine for new line
    dez
    dex
    bpl :-
    ldz #EDITFILE::firstLine+3
    ldx #3
:   lda ptr1,x
    nop
    sta (currentFile),z     ; Store new line as firstLine
    dez
    dex
    bpl :-
    rts

L0: ldz #EDITFILE::firstLine
    neg
    neg
    nop
    lda (currentFile),z
    jsr isQZero
    bne L1

    ; This is the first row
    ldz #EDITFILE::firstLine+3
    ldx #3
:   lda ptr1,x
    nop
    sta (currentFile),z
    dez
    dex
    bpl :-
    ; The editing buffer needs to be saved
    jsr closeGapBuf
    rts

L1: jsr currentEditorRow    ; Current line in ptr2

    ; If ptr2 is NULL then this is the last row
    ldq ptr2
    jsr isQZero
    bne L4                  ; Branch if not NULL
    ; Add this as the last line
    ldz #EDITFILE::firstLine
    neg
    neg
    nop
    lda (currentFile),z
    stq ptr2
L2: ldz #EDITLINE::next
    neg
    neg
    nop
    lda (ptr2),z
    jsr isQZero
    bne L3
    ldx #3
    ldz #EDITLINE::next+3
:   lda ptr1,x
    nop
    sta (ptr2),z
    dez
    dex
    bpl :-
    ldq ptr1
    stq ptr2
    rts
L3: stq ptr2
    bra L2

    ; Set the new line's "next" to the current line's
L4: ldz #EDITLINE::next
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr3                ; Store it ptr3 for a bit
    ldz #EDITLINE::next+3
    ldx #3
:   lda ptr3,x
    nop
    sta (ptr1),z
    dez
    dex
    bpl :-
    
    ; Set the current line's "next" to the new line
    ldz #EDITLINE::next+3
    ldx #3
:   lda ptr1,x
    nop
    sta (ptr2),z
    dez
    dex
    bpl :-

    rts
.endproc

