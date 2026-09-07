;
; editbuf.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; editor buffer routines

.include "asmlib.inc"
.include "editor.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export initEditBuf, editBufKey, isEditBufActive, getEditBufSyntaxColor
.export closeEditBuf, editBuf

.import incCurX, renderCursor, currentEditorRow, rowPtrs
.import editorInsertLine, syntaxHighlight, calcColorPtr
.import syntaxHighlightToColor, petsciiToScreenCode, screencols
.import decCurX, editorCombineLines, editorRowAt, anyDirtyRows

.bss

editBufValid: .res 1
editBuf: .res MAX_LINE_LENGTH       ; The buffer current being edited
syntaxBuf: .res MAX_LINE_LENGTH     ; Syntax highlighting for the buffer
continuedFromComment: .res 1        ; Non-zero if a comment is continued from previous line
continuedToComment: .res 1          ; Non-zero if a comment is continued to next line
screenPtr: .res 4                   ; Pointer to screen memory for the edited line

.code

.proc initEditBuf
    lda #0
    sta editBufValid

    rts
.endproc

; This routine is called when the user makes a change on the current line.
; It is called when the user types a character that results in an editing
; change. If the edit buffer is already set up, the change is made. If not,
; the buffer is set up first.
;
; Inputs:
;    A contains character typed
; Outputs:
;    Carry flag set if routine handled the keystroke
.proc editBufKey
    ; Backspace
BS: cmp #CH_BACKSPACE           ; Was the backspace hit?
    bne EN
    jmp editHandleBackspace

EN: cmp #CH_ENTER
    bne TB
    lda editBufValid            ; Is there an active gap buffer?
    beq :+                      ; Branch if not
    jsr closeEditBuf            ; Close out the gap buffer
:   clc                         ; Let the caller know it needs to handle this keystroke
    rts

TB: cmp #CH_TAB
    bne IN
    jsr handleTabStop
    sec
    rts

IN: cmp #CH_INS
    bne HM
    jsr handleInsertKey
    sec
    rts

HM: cmp #CH_HOME
    bne LF
    clc
    rts

    ; Cursor left
LF: cmp #CH_CURS_LEFT           ; Was it the left cursor?
    bne RT
    jmp editHandleCursorLeft

    ; Cursor right
RT: cmp #CH_CURS_RIGHT          ; Was it the right cursor?
    bne SL
    jmp editHandleCursorRight

    ; Delete to start of line
SL: cmp #CH_DELETE_SOL
    bne EL
    jsr editBufDeleteSOL
    sec
    rts

    ; Delete to end of line
EL: cmp #CH_DELETE_EOL
    bne NO
    jsr editBufDeleteEOL
    sec
    rts

    ; All other characters
NO: jsr setupEditBuf
    jsr insertChar
    clc
    jsr renderCursor
    jsr incCurX
    jsr renderBuffer
    sec
    rts
.endproc

; This routine calculates the length of the content in the
; editor buffer and returns it in A.
.proc calcEditLength
    ldx #0
L1: lda editBuf,x
    beq L2
    inx
    cpx #MAX_LINE_LENGTH
    bne L1
L2: txa
    rts
.endproc

; This routine closes out the edit buffer and saves the edits
; back to the line buffer.
.proc closeEditBuf
    lda editBufValid
    bne :+
    rts
:   ; Check if this is a new line in a new file
    jsr currentEditorRow
    ldq ptr2
    jsr isQZero
    bne :+                  ; Branch if not a new line
    ; This is a new line in a new file.
    jsr editorInsertLine
:   ; Calculate length of line in the gap buffer
    jsr calcEditLength
    sta tmp1                ; Store the length in tmp1
    pha                     ; Save the new line length on the stack
    ; Get the capacity of the current line
    ; Set ptr4 = row's current buffer
    ldz #EDITLINE::buffer
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr4
    ldz #EDITLINE::capacity
    nop
    lda (ptr2),z
    cmp tmp1                ; Is the new length <= line's current capacity?
    bcs L0                  ; branch if so

    ; Allocate a new buffer for the line
    pla
    pha
    jsr allocateLineBuffers
    jsr currentEditorRow
    ; Store the new length
L0: pla
    ldz #EDITLINE::length
    nop
    sta (ptr2),z
    lda #<editBuf
    sta ptr1
    sta intOp1
    lda #>editBuf
    sta ptr1+1
    sta intOp1+1

    ; Copy the edit buffer contents
    ldz #EDITLINE::buffer
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr4
    ldx #0
    ldz #0
L1: lda editBuf,x
    beq L2
    nop
    sta (ptr4),z
    inx
    inz
    bne L1
L2: lda #0
    sta editBufValid

    ; Update the syntax highlighting for this row
    ldz #EDITFILE::isPascal
    nop
    lda (currentFile),z
    bne :+
    rts
:   ldz #EDITLINE::length
    nop
    lda (ptr2),z
    pha
    ldz #EDITLINE::continuedComment
    nop
    lda (ptr2),z
    pha
    ldz #EDITLINE::buffer
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr1
    ldz #EDITLINE::syntaxHL
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    clc
    pla                     ; continuedComment flag
    beq :+
    sec
:   pla                     ; line length
    jsr syntaxHighlight
    bcc L3
    lda #1
    bra L4
L3: lda #0
L4: sta continuedToComment
    rts
.endproc

; This routine allocates a text buffer and syntax highlight
; buffer for the line.
;
; Inputs:
;    A - length of line
;    ptr2 - pointer to EDITLINE structure
.proc allocateLineBuffers
    pha                     ; Save line length on CPU stack
    ldq ptr2
    jsr pushQ               ; Save the EDITLINE pointer on the runtime stack
    ldz #EDITLINE::buffer
    neg
    neg
    nop
    lda (ptr2),z
    jsr isQZero
    beq L1                  ; Branch if the line has no buffer yet
    jsr heapFree            ; Free the old buffer
L1: pla                     ; Get the new length
    pha                     ; Then save it again
    ldx #0
    jsr heapAlloc
    stq ptr4
    jsr popQ
    stq ptr2
    ; Set the line's capacity
    pla
    pha
    ldz #EDITLINE::capacity
    nop
    sta (ptr2),z

    ; Store the new buffer in the EDITLINE structure
    ldz #EDITLINE::buffer
    ldx #0
:   lda ptr4,x
    nop
    sta (ptr2),z
    inz
    inx
    cpx #4
    bne :-

    ; Allocate a buffer for the syntax highlighting
    ldz #EDITFILE::isPascal
    nop
    lda (currentFile),z
    bne L2
    pla
    rts

L2: ldq ptr2
    jsr pushQ
    ldz #EDITLINE::syntaxHL
    neg
    neg
    nop
    lda (ptr2),z
    jsr isQZero
    beq L3
    jsr heapFree

L3: pla
    ldx #0
    jsr heapAlloc
    stq ptr4
    jsr popQ
    stq ptr2

    ; Store the new syntax buffer in the EDITLINE structure
    ldz #EDITLINE::syntaxHL
    ldx #0
:   lda ptr4,x
    nop
    sta (ptr2),z
    inz
    inx
    cpx #4
    bne :-

    rts
.endproc

.proc editBufDeleteEOL
    jsr setupEditBuf
    ldz #EDITFILE::cx
    nop
    lda (currentFile),z
    tax
    lda #0
    sta editBuf,x
    jsr renderBuffer
    rts
.endproc

.proc editBufDeleteSOL
    ; If the cursor is already in the first column, nothing to do.
    ldz #EDITFILE::cx
    nop
    lda (currentFile),z
    bne :+
    rts

:   jsr setupEditBuf

    ; If the cursor is positioned after the last character on the line,
    ; then clear the line.
    jsr calcEditLength
    sta tmp1
    ldz #EDITFILE::cx
    nop
    lda (currentFile),z
    cmp tmp1
    bne :+
    lda #0
    sta editBuf
    bra L2

    ; Calculate number of characters to copy
:   jsr calcEditLength
    sec
    ldz #EDITFILE::cx
    nop
    sbc (currentFile),z
    sta tmp1                    ; Number of characters to copy
    sta tmp2                    ; Put the new length in tmp2 as well

    ; Start the current cursor position and copy characters
    ; to the start of the edit buffer.
    nop
    lda (currentFile),z
    tax                         ; X is source index
    ldy #0                      ; Y is destination index
L1: lda editBuf,x
    sta editBuf,y
    inx
    iny
    dec tmp1
    bne L1

    ; Put a zero at the new end of the line
    lda #0
    ldx tmp2
    sta editBuf,x

L2: jsr renderBuffer

    ; Move the cursor to the first position
    clc
    jsr renderCursor
    ldz #EDITFILE::cx
    lda #0
    nop
    sta (currentFile),z
    sec
    jsr renderCursor

    rts
.endproc

.proc editHandleBackspace
    clc
    jsr renderCursor

    lda editBufValid
    bne L1                  ; Branch if an edit buffer is current in use

    ; An edit buffer is currently not in use.
    ; Check if the cursor is in the first column
    ldz #EDITFILE::cx
    nop
    lda (currentFile),z
    bne L2
    jsr editorCombineLines
    clc
    rts
    ; Is the cursor in the first column?
L1: ldz #EDITFILE::cx
    nop
    lda (currentFile),z
    beq BL
L2: jsr setupEditBuf
    bra BS

BL: ; Check to see if we are on the first line of the file
    ldz #EDITFILE::cy
    nop
    lda (currentFile),z
    inz
    nop
    ora (currentFile),z
    beq FI                  ; On the first line, ignore
    jsr closeEditBuf
    jsr editorCombineLines
FI: sec
    rts

BS: ; Calculate number of characters to copy
    jsr calcEditLength
    sta tmp2
    dec tmp2                    ; New length
    ldz #EDITFILE::cx
    sec
    nop
    sbc (currentFile),z
    beq L4
    sta tmp1                    ; Number of characters to copy

    ; Start the current cursor position and copy characters
    ; from the next position.
    ldz #EDITFILE::cx
    nop
    lda (currentFile),z
    tax                         ; X is the source index
    tay                         ; Y is destination index
    dey
L3: lda editBuf,x
    sta editBuf,y
    inx
    iny
    dec tmp1
    bne L3

    ; Put a zero at the new end of the line
L4: lda #0
    ldx tmp2
    sta editBuf,x

    jsr renderBuffer

    ; Move the cursor left one position
    jsr decCurX
    sec
    jsr renderCursor

    rts
.endproc

.proc editHandleCursorLeft
    clc
    lda editBufValid
    bne L1
    rts
L1: ldz #EDITFILE::cx
    nop
    lda (currentFile),z
    beq LC
    clc
    jsr renderCursor
    jsr decCurX
    jsr renderBuffer
    sec
    rts
LC: ; The user hit the left arrow in the first column
    jsr closeEditBuf
    clc
    rts
.endproc

.proc editHandleCursorRight
    clc
    lda editBufValid
    bne L1
    rts
L1: jsr calcEditLength
    sta tmp1
    ldz #EDITFILE::cx
    nop
    lda (currentFile),z
    cmp tmp1
    beq RC
    clc
    jsr renderCursor
    jsr incCurX
    jsr renderBuffer
    sec
    rts
RC: ; The user hit the right arrow in the last column
    jsr closeEditBuf
    clc
    rts
.endproc

; This routine returns one of SYNTAXHL_* defines values or
; SYNTAXHL_NONE if this is not a Pascal file being edited.
.proc getEditBufSyntaxColor
    ldz #EDITFILE::isPascal
    nop
    lda (currentFile),z
    bne L1
    lda #SYNTAXHL_NONE
    rts

L1: ldz #EDITFILE::cx
    nop
    lda (currentFile),z
    tax
    lda syntaxBuf,x
    rts
.endproc

.proc handleInsertKey
    jsr setupEditBuf
    lda #' '
    jsr insertChar
    jsr renderBuffer
    rts
.endproc

.proc handleTabStop
    jsr setupEditBuf    ; Make sure there's a valid edit buffer
    clc
    jsr renderCursor

    ; Get cursor's current column
    ldz #EDITFILE::cx
    nop
    lda (currentFile),z
    sta intOp1
    ora #3                      ; Calculate next tab stop
    sta intOp2
    inc intOp2                  ; intOp2 now contains next tab stop (4 spaces)
    ; Loop, inserting spaces until we reach the tab stop column
:   lda intOp1
    cmp intOp2
    beq :+
    lda #' '
    jsr insertChar
    jsr incCurX
    inc intOp1
    bne :-
:   jsr renderBuffer
    sec
    jsr renderCursor
    rts
.endproc

.proc insertChar
    pha             ; Save the new character on the stack
    ; Get the current buffer position
    ldz #EDITFILE::cx
    nop
    lda (currentFile),z
    sta tmp1
    ; Start at the end of the edit buffer, moving characters to the right.
    ldx #MAX_LINE_LENGTH-2
L1: lda editBuf,x
    sta editBuf+1,x
    cpx tmp1
    beq L2
    dex
    bra L1

L2: pla
    sta editBuf,x

    rts
.endproc

; This routine sets the Z flag if an edit buffer is currently active
.proc isEditBufActive
    lda editBufValid
    bne L1
    lda #1
    rts
L1: lda #0
    rts
.endproc

.proc renderBuffer
    ; First, do syntax highlighting for the edit buffer
    ldz #EDITFILE::isPascal
    nop
    lda (currentFile),z
    beq NP
    lda #<editBuf
    sta ptr1
    lda #>editBuf
    sta ptr1+1
    lda #0
    sta ptr1+2
    sta ptr1+3
    lda #<syntaxBuf
    sta ptr2
    lda #>syntaxBuf
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    jsr calcEditLength
    pha                     ; Save the buffer length on the stack
    clc
    lda continuedFromComment
    beq :+
    sec
:   pla
    pha
    jsr syntaxHighlight
    bcc NC
    lda #1
    bra SC
NC: lda #0

    ; If continuedToComment has changed then subsequent rows need to be re-rendered.
SC: sta continuedToComment
    jsr getNextRowContinuedComment
    cmp continuedToComment
    beq NP
    jsr rerenderSubsequentRows

NP: ldq screenPtr
    stq ptr3

    ; Calculate the row number on the screen
    ldz #EDITFILE::cy
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
    jsr subInt16
    ldy intOp1
    jsr calcColorPtr

    ; Loop through the buffer
    ldy #0
    ldz #0
    pla
    sta tmp1
L1: lda editBuf,y
    jsr petsciiToScreenCode
    sta (ptr3),y
    lda syntaxBuf,y
    jsr syntaxHighlightToColor
    nop
    sta (ptr1),z
    iny
    inz
    cpy tmp1
    bne L1

    ; Clear the rest of the row on the screen
    lda #' '
    jsr petsciiToScreenCode
L2: cpy screencols
    beq L3
    sta (ptr3),y
    iny
    bne L2

L3: rts
.endproc

; This routine returns the continuedComment value of the next row.
.proc getNextRowContinuedComment
    jsr currentEditorRow
    ldz #EDITLINE::next
    neg
    neg
    nop
    lda (ptr2),z
    jsr isQZero
    bne :+
    rts

:   stq ptr2
    ldz #EDITLINE::continuedComment
    nop
    lda (ptr2),z
    rts
.endproc

; This routine is called from renderBuffer when the edit-in-progress
; opens or closes a multi-line comment that is changed from the
; previous state. It runs through all following rows and recalculates
; syntax highlighting until it encounters a closing comment.
.proc rerenderSubsequentRows
    ldz #EDITFILE::isPascal
    nop
    lda (currentFile),z
    bne :+
    rts

    ; Start with the next row
:   ldz #EDITFILE::cy
    nop
    lda (currentFile),z
    sta intOp1
    inz
    nop
    lda (currentFile),z
    sta intOp1+1
    inw intOp1
    lda intOp1
    ldx intOp1+1
    jsr editorRowAt

    ; Loop through rows
L1: ldq ptr2
    jsr isQZero
    bne L2
    rts

    ; Does this row need to be re-rendered?
L2: ldz #EDITLINE::continuedComment
    nop
    lda (ptr2),z
    cmp continuedToComment
    beq L6

    ; Recalculate syntax highlighting for this row
    ldq ptr2
    jsr pushQ
    lda #1
    ldz #EDITLINE::dirty
    nop
    sta (ptr2),z
    sta anyDirtyRows
    ldz #EDITLINE::length
    nop
    lda (ptr2),z
    pha
    ldz #EDITLINE::buffer
    neg
    neg
    nop
    lda (ptr2),z
    jsr isQZero
    bne :+
    pla
    jsr popQ
    stq ptr2
    lda continuedToComment
    ldz #EDITLINE::continuedComment
    nop
    sta (ptr2),z
    bra L6
:   stq ptr1
    ldz #EDITLINE::syntaxHL
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    clc
    lda continuedToComment
    beq L3
    sec
L3: pla
    jsr syntaxHighlight
    bcc L4
    lda #1
    bra L5
L4: lda #0
L5: sta continuedToComment
    jsr popQ
    stq ptr2
    lda continuedToComment
    ldz #EDITLINE::continuedComment
    nop
    sta (ptr2),z

    ; Move to the next row
L6: ldz #EDITLINE::next
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    jmp L1
.endproc

.proc setupEditBuf
    ; See if the edit buffer is already set up
    pha
    lda editBufValid
    beq :+
    jmp DN

    ; Clear the buffer
:   lda #0
    ldx #MAX_LINE_LENGTH-1
:   sta editBuf,x
    sta syntaxBuf,x
    dex
    bpl :-

    lda #0
    sta continuedToComment

    ; Copy the contents of the current line into the buffer
    jsr currentEditorRow
    ldq ptr2
    stq ptr3
    ldz #EDITLINE::continuedComment
    nop
    lda (ptr3),z
    sta continuedFromComment
    ldz #EDITLINE::buffer
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr4
    ldz #EDITLINE::length
    nop
    lda (ptr3),z
    sta tmp1                    ; Store line length in tmp1 (for later)
    beq L1                      ; Branch if the line is empty
    tax
    ldy #0
    ldz #0
:   nop
    lda (ptr4),z
    sta editBuf,y
    iny
    inz
    dex
    bne :-

    ; Set up the screenPtr (screen memory for edited line)
L1: ldz #EDITFILE::cy
    nop
    lda (currentFile),z                 ; Put cursor Y in intOp1
    sta intOp1
    inz
    nop
    lda (currentFile),z
    sta intOp1+1
    ldz #EDITFILE::rowOff
    nop
    lda (currentFile),z                 ; Put top row offset in intOp2
    sta intOp2
    inz
    nop
    lda (currentFile),z
    sta intOp2+1
    jsr subInt16                        ; Calculate cursor Y - row offset
    lda intOp1
    asl a                               ; Multiply by four
    asl a
    tay
    ldx #0
:   lda rowPtrs,y
    sta screenPtr,x
    iny
    inx
    cpx #4
    bne :-
    lda #1
    sta editBufValid

DN: pla
    rts
.endproc
