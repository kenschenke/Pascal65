;
; gapbuf.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Gap buffer routines

.include "editor.inc"
.include "zeropage.inc"
.include "4510macros.inc"
.include "asmlib.inc"

.export editGapBuf, initGapBuf, closeGapBuf, gapBuf

.import currentEditorRow, rowPtrs, petsciiToScreenCode
.import incCurX, decCurX, editorCombineLines, renderCursor
.import isQZero, editorInsertLine, screencols

.bss

gapBuf: .res MAX_LINE_LENGTH    ; The gap buffer
gapLast: .res 2                 ; Pointer to the end of the gap buffer
gapValid: .res 1                ; Non-zero if the gap buffer is valid
screenPtr: .res 4               ; Pointer to screen memory for the edited line

.code

.proc initGapBuf
    lda #0
    sta gapValid

    lda #<gapBuf
    clc
    adc #MAX_LINE_LENGTH-1
    sta gapLast
    lda #>gapBuf
    adc #0
    sta gapLast+1
    rts
.endproc

; This routine is called when the user makes a change on the current line.
; It is called when the user types a character that results in an editing
; change. If the gap buffer is already set up, the change is made. If not,
; the gap buffer is set up first.
;
; Inputs:
;    A contains character typed
; Outputs:
;    Carry flag set if routine handled the keystroke
.proc editGapBuf
    ; Backspace
BS: cmp #CH_BACKSPACE           ; Was the backspace hit?
    bne EN
    jmp gapHandleBackspace

EN: cmp #CH_ENTER
    bne TB
    lda gapValid                ; Is there an active gap buffer?
    beq :+                      ; Branch if not
    jsr closeGapBuf             ; Close out the gap buffer
:   clc                         ; Let the caller know it needs to handle this keystroke
    rts

TB: cmp #CH_TAB
    bne IN
    jsr handleTabStop
    sec
    rts

IN: cmp #CH_INS
    bne HM
    jsr setupGapBuf
    dew gapEnd
    lda #' '
    ldy #0
    sta (gapEnd),y
    jsr renderBuffer
    sec
    rts

HM: cmp #CH_HOME
    bne LF
    lda gapValid
    bne :+
    clc
    rts
:   jsr gapHomeKey
    sec
    rts

    ; Cursor left
LF: cmp #CH_CURS_LEFT           ; Was it the left cursor?
    bne RT
    jmp gapHandleCursorLeft

    ; Cursor right
RT: cmp #CH_CURS_RIGHT          ; Was it the right cursor?
    bne SL
    jmp gapHandleCursorRight

    ; Delete to start of line
SL: cmp #CH_DELETE_SOL
    bne EL
    jsr gapBufDeleteSOL
    sec
    rts

    ; Delete to end of line
EL: cmp #CH_DELETE_EOL
    bne NO
    jsr gapBufDeleteEOL
    sec
    rts

    ; All other characters
NO: jsr setupGapBuf
    jsr insertChar
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; lda gapCursor
    ; ldx gapCursor+1
    ; lda #<gapBuf
    ; ldx #>gapBuf
    ; brk
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    clc
    jsr renderCursor
    jsr incCurX
    jsr renderBuffer
    sec
    rts
.endproc

.proc cmpStart
    lda gapCursor
    cmp #<gapBuf
    bne :+
    lda gapCursor+1
    cmp #>gapBuf
:   rts
.endproc

.proc gapHandleBackspace
    lda gapValid
    bne L1                      ; Branch if a gap buffer is currently valid
    ; A gap buffer is currently not in use.
    ; Check if the cursor is in the first column
    ldz #EDITFILE::cx
    nop
    lda (currentFile),z
    bne L2
    jsr editorCombineLines
    clc
    rts
L1: jsr cmpStart                ; Is the cursor in the first column?
    beq BL
L2: jsr setupGapBuf
    dew gapCursor
    clc
    jsr renderCursor
    jsr decCurX
    jsr renderBuffer
    sec
    rts
BL: ; Check to see if we are on the first line of the file
    ldz #EDITFILE::cy
    nop
    lda (currentFile),z
    inz
    nop
    ora (currentFile),z
    beq FI                      ; On the first line, ignore
    jsr closeGapBuf
    jsr editorCombineLines
FI: sec
    rts
.endproc

.proc gapHandleCursorLeft
    clc
    lda gapValid                ; Is there an active buffer?
    bne L1                      ; Branch if so
    rts
L1: jsr cmpStart
    bne L2                      ; Branch if the cursor is not in the first column
    bra LC                      ; Cursor in the first column
L2: dew gapCursor
    clc
    jsr renderCursor
    jsr decCurX
    dew gapEnd
    ldy #0
    lda (gapCursor),y
    sta (gapEnd),y
    sec
    rts
LC: ; The user hit the left arrow in the first column
    jsr closeGapBuf
    clc
    rts
.endproc

.proc gapHandleCursorRight
    clc
    lda gapValid                ; Is there an active buffer?
    bne L1                      ; Branch if not
    rts
L1: lda gapEnd
    cmp gapLast
    bne L2
    lda gapEnd+1
    cmp gapLast+1
    beq RC
L2: ldy #0
    lda (gapEnd),y
    sta (gapCursor),y
    inw gapCursor
    clc
    jsr renderCursor
    jsr incCurX
    inw gapEnd
    sec
    rts
RC: ; The user hit the right arrow in the last column
    jsr closeGapBuf
    clc
    rts
.endproc

.proc gapHomeKey
    jsr cmpStart
    beq :+
    dew gapCursor
    dew gapEnd
    ldy #0
    lda (gapCursor),y
    sta (gapEnd),y
    bne gapHomeKey
:   clc
    jsr renderCursor
    ldz #EDITFILE::cx
    lda #0
    nop
    sta (currentFile),z
    rts
.endproc

.proc handleTabStop
    jsr setupGapBuf             ; Make sure there's a valid gap buffer
    clc
    jsr renderCursor

    ; Calculate cursor's current column
    lda gapCursor
    sta intOp1
    lda gapCursor+1
    sta intOp1+1
    lda #<gapBuf
    sta intOp2
    lda #>gapBuf
    sta intOp2+1
    jsr subInt16
    inc intOp1                  ; Increment column by 1
    lda intOp1                  ; Copy cursor column to intOp2
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

; This routine inserts a character into the gap buffer at the cursor then moves the cursor
; Character to insert is passed in A
.proc insertChar
    ldx gapCursor
    cpx gapEnd
    bne :+
    ldx gapCursor+1
    cpx gapEnd+1
    beq FI
:   ldy #0
    sta (gapCursor),y
    inw gapCursor
FI: rts
.endproc

; This routine renders the gap buffer to the current row on the screen
;    ptr4 - pointer to current position in gap buffer
;    ptr3 - pointer to screen memory for the row
.proc renderBuffer
    lda #<gapBuf
    sta ptr4
    lda #>gapBuf
    sta ptr4+1
    ; Calculate ptr4+MAX_LINE_LENGTH
    lda ptr4
    clc
    adc #MAX_LINE_LENGTH
    sta intOp2
    lda ptr4+1
    adc #0
    sta intOp2+1
    ldz #0
    ; Copy screen ptr to ptr3
    ldx #3
:   lda screenPtr,x
    sta ptr3,x
    dex
    bpl :-
L1: ; if ptr4 == gapCursor then ptr4 = gapEnd
    lda ptr4
    cmp gapCursor
    bne :+
    lda ptr4+1
    cmp gapCursor+1
    bne :+
    ; Set ptr4 = gapEnd
    lda gapEnd
    sta ptr4
    lda gapEnd+1
    sta ptr4+1
:   ldy #0
    lda (ptr4),y
    jsr petsciiToScreenCode
    nop
    sta (ptr3),z
    inz
    inw ptr4
    ; if p >= buffer + sizeof(buffer)
    lda ptr4
    sta intOp1
    lda ptr4+1
    sta intOp1+1
    jsr ltUint16
    cmp #0
    bne L1
    ; Render spaces for the remainder of the line
    lda #' '
    dez
    dez
:   inz
    cpz screencols
    beq :+
    nop
    sta (ptr3),z
    bra :-
:   rts
.endproc

.proc setupGapBuf
    ; See if the gap buffer is already set up
    pha
    lda gapValid
    beq :+
    jmp DN

    ; Clear the gap buffer
:   lda #' '
    ldx #MAX_LINE_LENGTH-1
:   sta gapBuf,x
    dex
    bpl :-

    ; Copy the contents of the current line into the gap buffer
    jsr currentEditorRow
    ldq ptr2
    stq ptr3
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
    sta gapBuf,y
    iny
    inz
    dex
    bne :-
L1: ; Set the cursor pointer
    ldz #EDITFILE::cx
    lda #<gapBuf
    clc
    nop
    adc (currentFile),z
    sta gapCursor
    lda #>gapBuf
    adc #0
    sta gapCursor+1

    ; Calculate line length - cursor position
    ldz #EDITFILE::cx
    nop
    lda (currentFile),z
    sta tmp3
    lda tmp1
    sec
    sbc tmp3
    sta tmp2

    ; Set the end pointer
    lda #<gapBuf
    clc
    adc #MAX_LINE_LENGTH-1
    sta gapEnd
    lda #>gapBuf
    adc #0
    sta gapEnd+1
    lda gapEnd
    sec
    sbc tmp2
    sta gapEnd
    lda gapEnd+1
    sbc #0
    sta gapEnd+1

    ; Copy everything at and after the cursor to the end buffer
    ldy #0
    ldz #EDITFILE::cx
    nop
    lda (currentFile),z
    sta tmp2
    taz
    ; Subtract cursor position from line length
    lda tmp1
    sec
    sbc tmp2
    sta tmp1
L2: lda tmp1
    beq L3
    nop
    lda (ptr4),z
    sta (gapEnd),y
    iny
    inz
    dec tmp1
    bne L2

    ; Set up the screenPtr (screen memory for edited line)
L3: ldz #EDITFILE::cy
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
    sta gapValid

DN: pla
    rts
.endproc

; This routine calculates the length of content in the gap buffer.
; This is used by closeGapBuf to save the edit back to the line.
;
; Length is returned in A
.proc calcEditLength
    lda #0
    sta tmp1            ; character count

    lda #<gapBuf
    sta ptr1            ; ptr1 = current character in gap buffer
    lda #>gapBuf
    sta ptr1+1

    ; Calculate ptr1+MAX_LINE_LENGTH
    ; and store it intOp2
    lda ptr1
    clc
    adc #MAX_LINE_LENGTH
    sta intOp2
    lda ptr1+1
    adc #0
    sta intOp2+1

L1: ; Is the pointer at the end of the line
    lda ptr1
    sta intOp1
    lda ptr1+1
    sta intOp1+1
    jsr ltUint16
    cmp #0
    beq DN
    ; Is the cursor at the current character?
    lda ptr1
    cmp gapCursor
    bne L2
    lda ptr1+1
    cmp gapCursor+1
    bne L2
    ; Set ptr1 to gapEnd
    lda gapEnd
    sta ptr1
    lda gapEnd+1
    sta ptr1+1
L2: inw ptr1
    inc tmp1
    bne L1
DN: dec tmp1
    lda tmp1
    rts
.endproc

; This routine closes out the gap buffer and saves the edits
; back to the line buffer.
;    ptr4 - pointer to current position in gap buffer
;    ptr3 - pointer to screen memory for the row
.proc closeGapBuf
    lda gapValid
    bne :+
    rts
:   ; Check if the this is a new line in a new file
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
    ldz #EDITLINE::buffer
    neg
    neg
    nop
    lda (ptr2),z
    jsr isQZero
    beq :+                  ; Branch if the line had no buffer yet
    jsr heapFree            ; Free the old buffer
:   pla                     ; Get the new length
    pha                     ; Then save it again
    ldx #0
    jsr heapAlloc
    stq ptr4
    jsr currentEditorRow
    ldz #EDITLINE::buffer+3
    ldx #3
:   lda ptr4,x
    nop
    sta (ptr2),z
    dez
    dex
    bpl :-
    ; Store the new length
L0: pla
    ldz #EDITLINE::length
    nop
    sta (ptr2),z
    ldz #EDITLINE::capacity
    nop
    sta (ptr2),z
    lda #<gapBuf
    sta ptr1
    sta intOp1
    lda #>gapBuf
    sta ptr1+1
    sta intOp1+1
    ; Calculate ptr1+MAX_LINE_LENGTH
    lda ptr1
    clc
    adc #MAX_LINE_LENGTH-1
    sta intOp2
    lda ptr1+1
    adc #0
    sta intOp2+1
    ldz #0
    ldy #0
L1: ; if ptr1 == gapCursor then ptr1 = gapEnd
    lda intOp1
    cmp gapCursor
    bne :+
    lda intOp1+1
    cmp gapCursor+1
    bne :+
    ; Set ptr1 = gapEnd
    lda gapEnd
    sta ptr1
    sta intOp1
    lda gapEnd+1
    sta ptr1+1
    sta intOp1+1
    jsr eqInt16                 ; See if end of buffer is reached
    bne L2                      ; Branch if so
    ldy #0
:   lda (ptr1),y
    nop
    sta (ptr4),z
    inz
    iny
    inw intOp1
    ; if p >= buffer + sizeof(buffer)
    jsr ltUint16
    cmp #0
    bne L1

L2: lda #0
    sta gapValid
    rts
.endproc

; This routine deletes to the start of the line
.proc gapBufDeleteSOL
    jsr setupGapBuf         ; Make sure a gap buffer is currently open
    lda #<gapBuf
    sta gapCursor
    lda #>gapBuf
    sta gapCursor+1
    clc
    jsr renderCursor
    ldz #EDITFILE::cx
    lda #0
    nop
    sta (currentFile),z
    jsr renderBuffer
    rts
.endproc

; This routine deletes to the end of the line
.proc gapBufDeleteEOL
    jsr setupGapBuf         ; Make sure a gap buffer is currently open
    lda #<gapBuf
    clc
    adc #MAX_LINE_LENGTH-1
    sta gapEnd
    lda #>gapBuf
    adc #0
    sta gapEnd+1
    jsr renderBuffer
    rts
.endproc
