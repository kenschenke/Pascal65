;
; clipboard.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Clipboard routines

.include "editor.inc"
.include "zeropage.inc"
.include "4510macros.inc"
.include "asmlib.inc"

.export startTextSelection, editorCalcSelection, editorHighlightSelection
.export editorClearSelection, editorCopySelection, editorDeleteSelection
.export editorFreeClipboard, editorPasteClipboard

.import editorSetStatusMsg, isQZero, editorRowAt, editorSetAllRowsDirty
.import screenrows, calcScreenPtr
.import editorSetDefaultStatusMessage, clipboard
.import editorFreeLine, renderCursor, gapBuf
.import editorAllocLine
.import updateStatusBarFilename

.data

clipboardPrompt: .byte "'C': copy, 'X': cut, ", $5f, ": cancel", $0

.bss

currentHighlight: .res 2
currentScreenRow: .res 1
endHighlight: .res 2
linePtr: .res 4
lineIndex: .res 1

.code

; The clipboard is stored as a memory buffer, a random access read/write
; buffer. The clipboard text is stored in the buffer as a stream of characters.
; Line-endings are indicated with a carriage-return (PETSCII 13).

; Three values control text selection, copy, and cutting. All are stored in
; the EDITFILE struct. Those values are:
;
; selectionY    The cursor Y position when selection is turned on. The
;               code refers to this as the anchor point.
; startY        The Y position of the start of the selected region.
; endHY         The Y position of the end of the selected region.
;
; selectionY is set when the user turns on selection and does not change.
; startHY and endHY change as the user moves the cursor.

.proc startTextSelection
    ; First, make sure a file is open
    ldq currentFile
    jsr isQZero
    beq DN
    ; Make sure text selection is not already active
    ldz #EDITFILE::inSelection
    nop
    lda (currentFile),z
    bne DN
    ; Show the clipboard prompt
    lda #<clipboardPrompt
    ldx #>clipboardPrompt
    jsr editorSetStatusMsg
    ; Turn on text selection
    lda #1
    ldz #EDITFILE::inSelection
    nop
    sta (currentFile),z
    ; Set the anchor point
    ldz #EDITFILE::cy
    jsr loadY
    ldz #EDITFILE::selectionY
    jsr storeY
DN: rts
.endproc

.proc editorCalcSelection
    ; Make sure there is a file currently open
    ldq currentFile
    jsr isQZero
    bne :+
    rts

    ; Make sure selection is turned on
:   ldz #EDITFILE::inSelection
    nop
    lda (currentFile),z
    bne :+
    rts

    ; The selection is highlighted differently depending on whether
    ; the cursor is above or below the anchor point. The following
    ; code checks to see where the cursor is in relation to the anchor point.

    ; Check if the cursor Y is < anchor Y
:   ldz #EDITFILE::cy
    jsr loadY
    sta intOp1
    stx intOp1+1
    ldz #EDITFILE::selectionY
    jsr loadY
    sta intOp2
    stx intOp2+1
    jsr ltInt16
    beq cursorAfter
    ; The cursor is before the anchor point.
    ; The cursor is the starting point of the highlight
    ; and the anchor point is the end.
    ldz #EDITFILE::cy
    jsr loadY
    ldz #EDITFILE::startHY
    jsr storeY
    ldz #EDITFILE::selectionY
    jsr loadY
    ldz #EDITFILE::endHY
    jsr storeY
    bra DN
cursorAfter:
    ; The cursor is after the anchor point.
    ; The anchor point is the starting point of highlight
    ; and the cursor is the end.
    ldz #EDITFILE::selectionY
    jsr loadY
    ldz #EDITFILE::startHY
    jsr storeY
    ldz #EDITFILE::cy
    jsr loadY
    ldz #EDITFILE::endHY
    jsr storeY

DN: jsr editorSetAllRowsDirty
    rts
.endproc

.proc editorClearSelection
    ; Make sure a file is currently open
    ldq currentFile
    jsr isQZero
    beq DN

    ldz #EDITFILE::inSelection
    lda #0
    tax
    nop
    sta (currentFile),z
    ldz #EDITFILE::selectionY
    jsr storeY
    ldz #EDITFILE::startHY
    jsr storeY
    ldz #EDITFILE::endHY
    jsr storeY
    jsr editorSetAllRowsDirty
    jsr editorSetDefaultStatusMessage
DN: rts
.endproc

.proc editorCopySelection
    ; Delete any existing clipboard contents first
    jsr editorFreeClipboard

    ; Allocate a new clipboard
    jsr allocMemBuf
    stq clipboard

    ; Walk through the highlighted lines, starting at startHY.
    ldz #EDITFILE::startHY
    jsr loadY
    sta currentHighlight
    stx currentHighlight+1

L1: ; Check if currentHighlight > endHY
    lda currentHighlight
    sta intOp1
    lda currentHighlight+1
    sta intOp1+1
    ldz #EDITFILE::endHY
    jsr loadY
    sta intOp2
    stx intOp2+1
    jsr gtInt16
    beq :+
    jmp DN

    ; Get the EDITLINE for the current line
:   lda currentHighlight
    ldx currentHighlight+1
    jsr editorRowAt
    ldq ptr2
    stq ptr3
    stq linePtr
    ldq clipboard
    stq ptr1
    ldz #EDITLINE::buffer
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr2
    ldz #EDITLINE::length
    nop
    lda (ptr3),z
    ldx #0
    jsr writeToMemBuf
    
    ; Write a carriage return
    lda #13
    sta currentScreenRow
    lda #<currentScreenRow
    ldx #>currentScreenRow
    ldy #0
    ldz #0
    stq ptr2
    ldq clipboard
    stq ptr1
    lda #1
    ldx #0
    jsr writeToMemBuf

    ; Move to the next line
    ldq linePtr
    stq ptr2
    ldz #EDITLINE::next
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    stq linePtr
    inc currentHighlight
    bne :+
    inc currentHighlight+1
:   jmp L1

DN: rts
.endproc

.proc editorDeleteSelection
    clc
    jsr renderCursor

    ; Walk through the highlighted lines, starting on the last row of the selection.
    ldz #EDITFILE::endHY
    jsr loadY
    sta currentHighlight
    stx currentHighlight+1

L1: ; Are we past the first row of the selection?
    lda currentHighlight
    sta intOp1
    lda currentHighlight+1
    sta intOp1+1
    ldz #EDITFILE::startHY
    jsr loadY
    sta intOp2
    stx intOp2+1
    jsr ltInt16
    bne DN

    jsr clipboardDeleteRow

    lda currentHighlight
    sec
    sbc #1
    sta currentHighlight
    lda currentHighlight+1
    sbc #0
    sta currentHighlight+1
    bra L1

DN: ldz #EDITFILE::startHY
    jsr loadY
    ldz #EDITFILE::cy
    jsr storeY

    ; Mark the file dirty
    ldz #EDITFILE::dirty
    lda #1
    nop
    sta (currentFile),z
    jsr updateStatusBarFilename
    rts
.endproc

; This routine deletes the row currentHighlight
.proc clipboardDeleteRow
    ; Is currentHighlight the first row (row 0)?
    lda currentHighlight
    ora currentHighlight+1
    bne notFirst

    ; It's the first row.
    ldz #EDITFILE::firstLine
    neg
    neg
    nop
    lda (currentFile),z
    stq ptr3
    ; Load the "next" pointer
    ldz #EDITLINE::next
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr2
    ; Make it the new first line
    ldz #EDITFILE::firstLine+3
    ldx #3
:   lda ptr2,x
    nop
    sta (currentFile),z
    dez
    dex
    bpl :-
    ; Delete the old line
    ldq ptr3
    jsr editorFreeLine
    jmp finishUp

notFirst:
    ; Get the next row for the current row
    lda currentHighlight
    ldx currentHighlight+1
    jsr editorRowAt
    ldz #EDITLINE::next
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr3
    ; Get the previous line
    ldx currentHighlight+1
    ldy currentHighlight
    bne :+
    dex
:   dey
    tya
    jsr editorRowAt
    ; Set the previous line's "next"
    ldx #3
    ldz #EDITLINE::next+3
:   lda ptr3,x
    nop
    sta (ptr2),z
    dez
    dex
    bpl :-
    ; Free the current row
    ldq ptr3
    jsr editorFreeLine

finishUp:
    ldz #EDITFILE::numLines
    nop
    lda (currentFile),z
    sta intOp1
    inz
    nop
    lda (currentFile),z
    sta intOp1+1
    dew intOp1
    lda intOp1+1
    nop
    sta (currentFile),z
    dez
    lda intOp1
    nop
    sta (currentFile),z

    rts
.endproc

.proc editorFreeClipboard
    ; Is there a clipboard currently allocated?
    ldq clipboard
    jsr isQZero
    beq DN
    rts
    jsr freeMemBuf
    lda #0
    tax
    tay
    taz
    stq clipboard
DN: rts
.endproc

.proc editorPasteClipboard
    ; Make sure there is a file currently open
    ldq currentFile
    jsr isQZero
    bne :+
    rts

    ; Make sure there is contents in the clipboard
:   ldq clipboard
    jsr isQZero
    bne :+
    rts

:   clc
    jsr renderCursor

    ldq clipboard
    stq ptr1
    lda #0
    tax
    jsr setMemBufPos

    lda #0
    sta lineIndex

L1: ; Are we at the end of the clipboard buffer?
    ldq clipboard
    jsr isMemBufAtEnd
    beq DN

    ; Read one character from the clipboard
    ldq clipboard
    stq ptr1
    lda #<gapBuf
    clc
    adc lineIndex
    sta ptr2
    lda #>gapBuf
    adc #0
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #1
    ldx #0
    jsr readFromMemBuf
    lda #<gapBuf
    sta ptr1
    lda #>gapBuf
    sta ptr1+1
    ldy lineIndex
    lda (ptr1),y
    cmp #13
    beq L2
    inc lineIndex
    bra L1

    ; Insert the new line
L2: jsr insertClipboardLine
    ; Move the cursor down by one line
    ldz #EDITFILE::cy
    nop
    lda (currentFile),z
    sta intOp1
    inz
    nop
    lda (currentFile),z
    sta intOp1+1
    inw intOp1
    lda intOp1+1
    nop
    sta (currentFile),z
    dez
    lda intOp1
    nop
    sta (currentFile),z
    bra L1

DN: jsr editorSetAllRowsDirty
    
    ; Mark the file dirty
    ldz #EDITFILE::dirty
    lda #1
    nop
    sta (currentFile),z
    jsr updateStatusBarFilename
    rts
.endproc

.proc insertClipboardLine
    ; Allocate an EDITLINE structure
    jsr editorAllocLine
    ldq ptr1
    stq linePtr
    lda lineIndex
    ldz #EDITLINE::length
    nop
    sta (ptr1),z
    ldz #EDITLINE::capacity
    nop
    sta (ptr1),z

    ; Allocate a buffer for the characters
    lda lineIndex
    ldx #0
    jsr heapAlloc
    stq ptr2

    ; Store the buffer pointer in the EDITLINE structure
    ldq linePtr
    stq ptr3
    ldz #EDITLINE::buffer+3
    ldx #3
:   lda ptr2,x
    nop
    sta (ptr3),z
    dez
    dex
    bpl :-

    ; Copy characters
    ldx #0
    ldz #0
    lda lineIndex
    beq L1
:   lda gapBuf,x
    nop
    sta (ptr2),z
    inx
    inz
    dec lineIndex
    bne :-

L1: ldz #EDITFILE::firstLine
    neg
    neg
    nop
    lda (currentFile),z
    jsr isQZero
    bne L2
    ; The new line is the new first line
    stq ptr4
    ldz #EDITLINE::next+3
    ldx #3
:   lda ptr4,x
    nop
    sta (ptr3),z
    dez
    dex
    bpl :-
    ldz #EDITFILE::firstLine+3
    ldx #3
:   lda ptr3,x
    nop
    sta (currentFile),z
    dez
    dex
    bpl :-
    bra DN

L2: ldz #EDITFILE::cy
    jsr loadY
    sta intOp1
    stx intOp1+1
    dew intOp1
    lda intOp1
    ldx intOp1+1
    jsr editorRowAt
    ; Copy the previous row's next into ptr4
    ldz #EDITLINE::next
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr4
    ; Set the previous row's next to ptr3 (the new line)
    ldz #EDITLINE::next+3
    ldx #3
:   lda ptr3,x
    nop
    sta (ptr2),z
    dez
    dex
    bpl :-
    ; Set the new line's next to the previous line's old next
    ldz #EDITLINE::next+3
    ldx #3
:   lda ptr4,x
    nop
    sta (ptr3),z
    dez
    dex
    bpl :-

    ; Increment number of lines in the file
DN: ldz #EDITFILE::numLines
    nop
    lda (currentFile),z
    sta intOp1
    inz
    nop
    lda (currentFile),z
    sta intOp1+1
    inw intOp1
    lda intOp1+1
    nop
    sta (currentFile),z
    dez
    lda intOp1
    nop
    sta (currentFile),z
    rts
.endproc

; This routine is called after editorDrawRows to highlight
; the selection.
.proc editorHighlightSelection
    ; Is there a file currently open?
    ldq currentFile
    jsr isQZero
    bne :+
    jmp DN

    ; Is there an active selection?
:   ldz #EDITFILE::inSelection
    nop
    lda (currentFile),z
    bne :+
    jmp DN

    ; Set up variables
:   ldz #EDITFILE::startHY
    jsr loadY
    sta currentHighlight
    stx currentHighlight+1
    ldz #EDITFILE::endHY
    jsr loadY
    sta endHighlight
    stx endHighlight+1

    ; Is currentHighlight < rowOff (off the screen)?
    lda currentHighlight
    sta intOp1
    lda currentHighlight+1
    sta intOp1+1
    ldz #EDITFILE::rowOff
    nop
    lda (currentFile),z
    sta intOp2
    inz
    nop
    lda (currentFile),z
    sta intOp2+1
    jsr ltInt16
    beq :+
    ; It is, so set currentHighlight to rowOff
    lda intOp2
    sta currentHighlight
    lda intOp2+1
    sta currentHighlight+1

    ; Is endHighlight not visible?
    ; rowOff is still in intOp2. Add screenrows to it.
:   lda screenrows
    sta intOp1
    lda #0
    sta intOp1+1
    jsr addInt16
    lda intOp1
    sta intOp2
    lda intOp1+1
    sta intOp2+1
    lda endHighlight
    sta intOp1
    lda endHighlight+1
    sta intOp1+1
    jsr gtInt16
    beq :+
    ; endHighlight is off the bottom of the screen.
    ; Set endHighlight to rowOff+screenrows
    lda intOp2
    sta endHighlight
    lda intOp2+1
    sta endHighlight+1

    ; Set currentScreenRow
:   lda currentHighlight
    sta intOp1
    lda currentHighlight+1
    sta intOp1+1
    ldz #EDITFILE::rowOff
    nop
    lda (currentFile),z
    sta intOp2
    inz
    nop
    lda (currentFile),z
    sta intOp2+1
    jsr subInt16
    lda intOp1
    sta currentScreenRow

L1: lda currentHighlight
    sta intOp1
    lda currentHighlight+1
    sta intOp1+1
    lda endHighlight
    sta intOp2
    lda endHighlight+1
    sta intOp2+1
    jsr gtInt16
    beq L2
    jmp DN

L2: ; Highlight
    lda currentHighlight
    ldx currentHighlight+1
    jsr editorRowAt
    ldz #EDITLINE::length
    nop
    lda (ptr2),z
    sta tmp2
    ldy currentScreenRow
    jsr calcScreenPtr
    ldz #0
L5: cpz tmp2
    beq L6
    nop
    lda (ptr4),z
    ora #$80
    nop
    sta (ptr4),z
    inz
    bne L5

L6: inc currentHighlight
    bne :+
    inc currentHighlight+1
:   inc currentScreenRow
    jmp L1

DN: rts
.endproc

; This routine loads the current cursor Y position into A/X
.proc loadY
    inz
    nop
    lda (currentFile),z
    tax
    dez
    nop
    lda (currentFile),z
    rts
.endproc

; This routine stores A/X into the startHY
.proc storeY
    nop
    sta (currentFile),z
    txa
    inz
    nop
    sta (currentFile),z
    rts
.endproc
