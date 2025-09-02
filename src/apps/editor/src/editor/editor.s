;
; editor.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Main editor functionality

.include "zeropage.inc"
.include "editor.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"
.include "asmlib.inc"

.export initEditor, titleScreen, screencols, screenrows, clipboard
.export statusmsg, statusmsg_dirty, anyDirtyRows, rowPtrs, editorRun, statusbar
.export editorSetDefaultStatusMessage, updateStatusBarFilename
.export editorSetAllRowsDirty, incCurX, decCurX, initFile
.export colorPtrs, editorAllocLine, isQZero, editorFreeLine, editorSetStatusMsg
.export editorNewFile, firstFile, addCurrentFile, editorHandleFileSave
.export editorHandleFileSaveAs

.import readTitleFile, editorRefreshScreen, openHelpFile
.import renderCursor, currentEditorRow, editGapBuf, initGapBuf, closeGapBuf
.import editorEnterKey, editorReadKey, clearScreen, showDirScreen, showFileScreen
.import saveToExisting, fileSaveAs, editorDrawMessageBar
.import startTextSelection, editorCalcSelection, editorClearSelection, editorCopySelection
.import editorDeleteSelection, editorPasteClipboard, initScreen, setupScreen
.import editorSaveState, editorRestoreState, editorHasState, fnBuf, runCompiler

.data

defaultStatusMsg: .byte "F1: open  F3: save  F5: run  F7: compile  ", $5f, ": files  Ctrl-X: quit", $0
promptUnsavedFiles: .asciiz "Unsaved files. Exit anyway? Y/N"
welcomeMsg: .asciiz "Welcome"
nofilename: .asciiz "[No Name]"
readonlymsg: .asciiz "R/O"
colLabel: .asciiz "C:"
rowLabel: .asciiz "R:"
fivediceFilename: .asciiz "fivedice.pas"

.bss

firstFile: .res 4           ; Pointer to first file open in the editor
titleScreen: .res 4         ; Pointer to title screen contents
clipboard: .res 4           ; Pointer to clipboard contents (linked list of CLIPLINE)
screenrows: .res 1          ; # of rows on display
screencols: .res 1          ; # of columns
statusmsg: .res DEFAULT_COLS
statusbar: .res DEFAULT_COLS
statusmsg_dirty: .res 1
anyDirtyRows: .res 1
loopCode: .res 1

rowPtrs: .res 200           ; 50 rows * 4 bytes -- pointers to screen memory for each row
colorPtrs: .res 200         ; 50 rows * 4 bytes -- pointers to color RAM

prevRow: .res 4

.code

.proc initEditor
    lda #0
    sta statusmsg
    sta statusmsg_dirty
    lda #1
    sta anyDirtyRows

    jsr initScreen

    ldx #DEFAULT_COLS-1
    lda #' '
:   sta statusbar,x
    dex
    bpl :-

    jsr editorSetDefaultStatusMessage

    lda #6
    sta $d020
    sta $d021

    jsr clearScreen

    ; Read the title file
    jsr initTitleFile
    lda #1
    sta anyDirtyRows

    lda #0
    tax
    tay
    taz
    stq currentFile
    stq firstFile
    stq clipboard

    ; Check if a state file exists
    jsr editorHasState
    beq :+
    jsr editorRestoreState

:   lda #EDITOR_LOOP_CONTINUE
    sta loopCode

    jsr initGapBuf
    
    rts
.endproc

.proc initTitleFile
    ; Allocate memory
    lda #.sizeof(EDITFILE)
    ldx #0
    jsr heapAlloc
    stq titleScreen
    stq currentFile
    ; Clear the EDITFILE struct
    ldz #.sizeof(EDITFILE)-1
    lda #0
:   nop
    sta (currentFile),z
    dez
    bpl :-
    jmp readTitleFile
.endproc

.proc decCurX
    ldz #EDITFILE::cx
    nop
    lda (currentFile),z
    sec
    sbc #1
    nop
    sta (currentFile),z
    rts
.endproc

.proc incCurX
    ldz #EDITFILE::cx
    nop
    lda (currentFile),z
    clc
    adc #1
    nop
    sta (currentFile),z
    rts
.endproc

; This routine allocates a new EDITLINE structure and leaves the
; address in ptr1.
.proc editorAllocLine
    lda #.sizeof(EDITLINE)
    ldx #0
    jsr heapAlloc
    neg
    neg
    sta ptr1
    ldz #.sizeof(EDITLINE)-1
    lda #0
:   nop
    sta (ptr1),z
    dez
    bpl :-
    ; Mark the line as dirty
    ldz #EDITLINE::dirty
    lda #1
    nop
    sta (ptr1),z
    rts
.endproc

; This routine looks at the open files. If any are unsaved it sets the Z flag.
; Otherwise, the Z flag is cleared.
.proc editorAnyUnsavedFiles
    ldq firstFile
    stq ptr1
L1: jsr isQZero
    beq DN
    ldz #EDITFILE::dirty
    nop
    lda (ptr1),z
    beq L2
DN: rts
L2: ldz #EDITFILE::nextFile
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    bra L1
.endproc

.proc editorProcessKeypress
    lda #EDITOR_LOOP_CONTINUE
    sta loopCode

    jsr editorReadKey

    cmp #CH_25_ROWS
    bne :+
    jmp editorHandle25Rows
:   cmp #CH_50_ROWS
    bne :+
    jmp editorHandle50Rows
:   cmp #CH_CURS_DOWN
    bne :+
    jmp editorCursorDown
:   cmp #CH_CURS_UP
    bne :+
    jmp editorCursorUp
:   cmp #CH_CURS_LEFT
    bne :+
    jmp editorCursorLeft
:   cmp #CH_CURS_RIGHT
    bne :+
    jmp editorCursorRight
:   jsr editorHandleSelectionKeys
    bcc :+
    rts
:   cmp #CTRL_X
    bne :+
    jmp editorHandleCtrlX
:   cmp #CH_HOME
    bne :+
    jmp editorHome
:   cmp #CH_BACKARROW
    bne :+
    jmp showFileScreen
:   cmp #CH_F1
    bne :+
    jmp showDirScreen
:   cmp #CH_F3
    bne :+
    jmp editorHandleFileSave
:   cmp #CH_F5
    bne :+
    jmp editorHandleRunAndCompile
:   cmp #CH_F7
    bne :+
    jmp editorHandleRunAndCompile
:   cmp #CH_HELP
    bne :+
    jmp openHelpFile
:   cmp #CTRL_B
    bne :+
    jmp editorHandleCtrlB
:   cmp #CTRL_E
    bne :+
    jmp editorHandleCtrlE
:   cmp #CTRL_J
    bne :+
    jmp editorHandleCtrlJ
:   cmp #CTRL_K
    bne :+
    jmp editorHandleCtrlK
:   cmp #CTRL_P
    bne :+
    jmp editorHandleCtrlP
:   cmp #CTRL_N
    bne :+
    jmp editorHandleCtrlN
:   cmp #CTRL_U
    bne :+
    jmp editorHandleCtrlU
:   cmp #CTRL_V
    bne :+
    jmp editorHandleCtrlV
:   cmp #CTRL_W
    bne :+
    jmp editorHandleCtrlW
:   cmp #CTRL_Y
    bne :+
    jmp editorHandleCtrlY
    ; The rest of the keys are file-modifying.
    ; Check if a file is currently open
:   jsr isFileOpen
    bcc DN
    ; Check if the file is read-only and ignore the keystroke if so.
    jsr isReadOnly
    bcs DN                  ; Branch if file is read-only
    jsr isDirty
    bcs :+
    pha                     ; Save the keystroke on the stack
    lda #1
    ldz #EDITFILE::dirty
    nop
    sta (currentFile),z
    jsr updateStatusBarFilename
    pla                     ; Pop the keystroke back off the stack
:   cmp #CH_ENTER
    bne :+
    jsr editGapBuf
    jmp editorEnterKey
:   cmp #CH_TAB
    bne :+
:   ; Any other keystroke handled by editGapBuf
    jmp editGapBuf
DN: rts
.endproc

.proc editorCursorUp
    ; First, make sure the cursor position > 0
    ldz #EDITFILE::cy
    nop
    lda (currentFile),z
    inz
    nop
    ora (currentFile),z
    beq DN                  ; Branch if row is already 0
    jsr closeGapBuf
    clc
    jsr renderCursor
    ldz #EDITFILE::cy
    nop
    lda (currentFile),z
    sec
    sbc #1
    nop
    sta (currentFile),z
    inz
    nop
    lda (currentFile),z
    sbc #0
    nop
    sta (currentFile),z
    jsr checkCursorEOL
    jsr editorCalcSelection
DN: rts
.endproc

.proc editorCursorDown
    ; First, make sure the cursor isn't moving past the last line of the file
    ldz #EDITFILE::cy
    nop
    lda (currentFile),z
    sta intOp1
    inz
    nop
    lda (currentFile),z
    sta intOp1+1
    ldz #EDITFILE::numLines
    nop
    lda (currentFile),z
    sta intOp2
    inz
    nop
    lda (currentFile),z
    sta intOp2+1
    jsr geInt16
    bne DN

    jsr closeGapBuf

    clc
    jsr renderCursor
    ldz #EDITFILE::cy
    nop
    lda (currentFile),z
    clc
    adc #1
    nop
    sta (currentFile),z
    inz
    nop
    lda (currentFile),z
    adc #0
    nop
    sta (currentFile),z
    jsr checkCursorEOL
    jsr editorCalcSelection
DN: rts
.endproc

.proc editorCursorLeft
    jsr editGapBuf
    bcs DN                  ; Branch if editGapBuf handled the key
    ; First, make sure the cursor position > 0
    ldz #EDITFILE::cx
    nop
    lda (currentFile),z
    beq UP                  ; Branch if column is already 0
    clc
    jsr renderCursor
    jsr decCurX
    jmp DN
UP: ; Cursor is in first column. Is it also in the first row?
    ldz #EDITFILE::cy
    nop
    lda (currentFile),z
    inz
    nop
    ora (currentFile),z
    beq DN                  ; Branch if also in first row
    ; Move up one row and put the cursor at the end of the row
    jsr editorCursorUp
    jsr currentEditorRow
    ldz #EDITLINE::length
    nop
    lda (ptr2),z
    ldz #EDITFILE::cx
    nop
    sta (currentFile),z
DN: jsr editorCalcSelection
    rts
.endproc

.proc editorCursorRight
    jsr editGapBuf
    bcs DN                  ; Branch if editGapBuf handled the key
    ; First, check if the cursor is at the end of the line
    ldz #EDITFILE::cx
    nop
    lda (currentFile),z
    sta tmp1
    jsr currentEditorRow
    ldz #EDITLINE::length
    nop
    lda (ptr2),z
    cmp tmp1
    beq DW
    clc
    jsr renderCursor
    jsr incCurX
    jmp DN
DW: ; Make sure we're not already on the last row
    ldz #EDITFILE::numLines
    nop
    lda (currentFile),z
    sta intOp1
    inz
    nop
    lda (currentFile),z
    sta intOp1+1
    ldz #EDITFILE::cy
    nop
    lda (currentFile),z
    sta intOp2
    inz
    nop
    lda (currentFile),z
    sta intOp2+1
    jsr eqInt16
    bne DN
    clc
    jsr renderCursor
    ; Move to the next line
    ldz #EDITFILE::cy
    nop
    lda (currentFile),z
    clc
    adc #1
    nop
    sta (currentFile),z
    inz
    nop
    lda (currentFile),z
    adc #0
    nop
    sta (currentFile),z
    ; Put the cursor in the first column
    ldz #EDITFILE::cx
    lda #0
    nop
    sta (currentFile),z
    sec
    jsr renderCursor
DN: jsr editorCalcSelection
    rts
.endproc

.proc editorHome
    jsr editGapBuf
    bcs DN                  ; Branch if editGapBuf handled the key
    clc
    jsr renderCursor
    ldz #EDITFILE::cx
    lda #0
    nop
    sta (currentFile),z
    sec
    jsr renderCursor
DN: rts
.endproc

; This routine frees memory for the line in Q
.proc editorFreeLine
    pha
    phx
    phy
    phz
    neg
    neg
    sta ptr1
    ldz #EDITLINE::buffer
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    jsr heapFree
:   plz
    ply
    plx
    pla
    jsr heapFree
    rts
.endproc

; This routine checks if the cursor position is past the end of the line.
; This called by editorCursorUp and editorCursorDown. If the cursor is
; past the EOL, it places the cursor at the last character on the line.
.proc checkCursorEOL
    ; Look up the cursor position
    ldz #EDITFILE::cx
    nop
    lda (currentFile),z
    sta tmp1
    ; Look up the length of the new line
    jsr currentEditorRow
    ldz #EDITLINE::length
    nop
    lda (ptr2),z
    cmp tmp1
    bcs DN
    ; Move to the cursor to the end of the new line
    ldz #EDITFILE::cx
    nop
    sta (currentFile),z
DN: rts
.endproc

.proc editorNewFile
    jsr initFile
    jsr addCurrentFile
    jsr updateStatusBarFilename
    jsr editorSetDefaultStatusMessage
    jsr clearScreen
    jsr editorSetAllRowsDirty
    rts
.endproc

; This routine is the main loop of the editor. It runs until
; the user exits with Ctrl+X. On exit, it JMPs to the KERNAL reset vector.
.proc editorRun
L1: lda loopCode
    cmp #EDITOR_LOOP_CONTINUE
    bne L2
    jsr editorRefreshScreen
    jsr editorProcessKeypress
    bra L1
L2: jmp ($fffc)
.endproc

.proc editorHandle25Rows
    ldx #DEFAULT_COLS
    ldy #25
    bra editorChangeScreenSize
.endproc

.proc editorHandle50Rows
    ldx #DEFAULT_COLS
    ldy #50
    ; Fall through to editorChangeScreenSize
.endproc

.proc editorChangeScreenSize
    jsr setupScreen
    jsr clearScreen
    jsr editorSetAllRowsDirty
    lda #1
    sta anyDirtyRows
    sta statusmsg_dirty
    rts
.endproc

; This routine handles the user pressing Ctrl+B or Esc+B
; which moves the cursor to the top of the file
.proc editorHandleCtrlB
    clc
    jsr renderCursor
    lda #0
    ldz #EDITFILE::rowOff
    nop
    sta (currentFile),z
    inz
    nop
    sta (currentFile),z
    ldz #EDITFILE::cy
    nop
    sta (currentFile),z
    inz
    nop
    sta (currentFile),z
    ldz #EDITFILE::cx
    nop
    sta (currentFile),z
    jsr editorSetAllRowsDirty
    rts
.endproc

; This routine handles the user pressing Ctrl+E or Esc+E
; which moves the cursor to the bottom of the file
.proc editorHandleCtrlE
    clc
    jsr renderCursor
    ; Calculate numLines-screenrows
    ldz #EDITFILE::numLines
    nop
    lda (currentFile),z
    sta intOp1
    inz
    nop
    lda (currentFile),z
    sta intOp1+1
    lda screenrows
    sta intOp2
    lda #0
    sta intOp2+1
    jsr subInt16
    ; Stop numLines-screenrows in rowOff
    ldz #EDITFILE::rowOff
    lda intOp1
    bpl :+
    lda #0
    sta intOp1
    sta intOp1+1
:   nop
    sta (currentFile),z
    inz
    lda intOp1+1
    nop
    sta (currentFile),z
    ldz #EDITFILE::cx
    lda #0
    nop
    sta (currentFile),z
    ldz #EDITFILE::numLines
    nop
    lda (currentFile),z
    pha
    inz
    nop
    lda (currentFile),z
    ldz #EDITFILE::cy+1
    nop
    sta (currentFile),z
    dez
    pla
    nop
    sta (currentFile),z
    jsr editorSetAllRowsDirty
    rts
.endproc

; This routine handles the user pressing Ctrl+J or Esc+J
; which moves the cursor to the first column
.proc editorHandleCtrlJ
    clc
    jsr renderCursor
    ldz #EDITFILE::cx
    lda #0
    nop
    sta (currentFile),z
    jmp renderCursor
.endproc

; This routine handles the user pressing Ctrl+K or Esc+K
; which moves the cursor to the last character on the line
.proc editorHandleCtrlK
    jsr closeGapBuf
    clc
    jsr renderCursor
    jsr currentEditorRow
    ldz #EDITLINE::length
    nop
    lda (ptr2),z
    ldz #EDITFILE::cx
    nop
    sta (currentFile),z
    sec
    jmp renderCursor
.endproc

; This routine handles the user pressing CTRL+N or Esc+Dn
; which does a page-down.
.proc editorHandleCtrlN
    clc
    jsr renderCursor
    jsr closeGapBuf
    ; Add screenrows to rowOff (top row on screen)
    ldz #EDITFILE::rowOff
    nop
    lda (currentFile),z
    sta intOp1
    inz
    nop
    lda (currentFile),z
    sta intOp1+1
    lda screenrows
    sta intOp2
    lda #0
    sta intOp2+1
    jsr addInt16
    ; Is rowOff > numLines-screenrows?
    lda intOp1
    pha
    lda intOp1+1
    pha
    ldz #EDITFILE::numLines
    nop
    lda (currentFile),z
    sta intOp1
    inz
    nop
    lda (currentFile),z
    sta intOp1+1
    lda screenrows
    sta intOp2
    lda #0
    sta intOp2+1
    jsr subInt16
    pla
    sta intOp1
    pla
    sta intOp1+1
    jsr geInt16
    beq :+
    lda intOp2
    sta intOp1
    lda intOp2+1
    sta intOp1+1
:   ldz #EDITFILE::rowOff   ; Store difference back in rowOff
    lda intOp1
    nop
    sta (currentFile),z
    inz
    lda intOp1+1
    nop
    sta (currentFile),z
    ; Add screenrows to cy
    ldz #EDITFILE::cy
    nop
    lda (currentFile),z
    sta intOp1
    inz
    nop
    lda (currentFile),z
    sta intOp1+1
    lda screenrows
    sta intOp2
    lda #0
    sta intOp2+1
    jsr addInt16
    ; Is cy > numLines?
    ldz #EDITFILE::numLines
    nop
    lda (currentFile),z
    sta intOp2
    inz
    nop
    lda (currentFile),z
    sta intOp2+1
    jsr geInt16
    beq :+
    lda intOp2
    sta intOp1
    lda intOp2+1
    sta intOp1+1
:   ldz #EDITFILE::cy
    lda intOp1
    nop
    sta (currentFile),z
    inz
    lda intOp1+1
    nop
    sta (currentFile),z
    jsr checkCursorEOL
    jmp editorSetAllRowsDirty
.endproc

; This routine handles the user pressing CTRL+P or Esc+Up
; which does a page-up.
.proc editorHandleCtrlP
    clc
    jsr renderCursor
    jsr closeGapBuf
    ; Subtract screenrows from rowOff (top row on screen)
    ldz #EDITFILE::rowOff
    nop
    lda (currentFile),z
    sta intOp1
    inz
    nop
    lda (currentFile),z
    sta intOp1+1
    lda screenrows
    sta intOp2
    lda #0
    sta intOp2+1
    jsr subInt16
    lda intOp1+1
    bpl :+                  ; branch if rowOffset >= 0
    lda #0                  ; make it zero
    sta intOp1
    sta intOp1+1
:   ldz #EDITFILE::rowOff   ; Store difference back in rowOff
    lda intOp1
    nop
    sta (currentFile),z
    inz
    lda intOp1+1
    nop
    sta (currentFile),z
    ; Subtract screenrows from cy
    ldz #EDITFILE::cy
    nop
    lda (currentFile),z
    sta intOp1
    inz
    nop
    lda (currentFile),z
    sta intOp1+1
    lda screenrows
    sta intOp2
    lda #0
    sta intOp2+1
    jsr subInt16
    lda intOp1+1
    bpl :+
    lda #0
    sta intOp1
    sta intOp1+1
:   ldz #EDITFILE::cy
    lda intOp1
    nop
    sta (currentFile),z
    inz
    lda intOp1+1
    nop
    sta (currentFile),z
    jsr checkCursorEOL
    jmp editorSetAllRowsDirty
.endproc

; This routine handles the user pressing CTRL+U
; which pastes from the clipboard.
.proc editorHandleCtrlU
    ; First, we want to close out any open gap buffer
    jsr closeGapBuf
    jsr editorPasteClipboard
    rts
.endproc

; This handles the user pressing CTRL+V or Esc+V
; which scrolls the display up one line.
.proc editorHandleCtrlV
    ; First see if the row offset is already zero
    ldz #EDITFILE::rowOff
    nop
    lda (currentFile),z
    bne :+
    inz
    nop
    lda (currentFile),z
    bne :+
    rts
:   clc
    jsr renderCursor
    ldz #EDITFILE::rowOff
    nop
    lda (currentFile),z
    sec
    sbc #1
    nop
    sta (currentFile),z
    sta intOp1
    inz
    nop
    lda (currentFile),z
    sbc #0
    nop
    sta (currentFile),z
    sta intOp1+1
    ; If cy > rowOff+screenrows then set cy = rowOff+screenrows
    lda screenrows
    sta intOp2
    lda #0
    sta intOp2+1
    jsr addInt16
    lda intOp1
    sta intOp2
    lda intOp1+1
    sta intOp2+1
    ldz #EDITFILE::cy
    nop
    lda (currentFile),z
    sta intOp1
    inz
    nop
    lda (currentFile),z
    sta intOp1+1
    jsr geInt16
    beq :+
    dew intOp2
    ldz #EDITFILE::cy
    lda intOp2
    nop
    sta (currentFile),z
    inz
    lda intOp2+1
    nop
    sta (currentFile),z
:   jsr editorSetAllRowsDirty
    rts
.endproc

; This handles the user pressing CTRL+W or Esc+W
; which scrolls the display down one line.
.proc editorHandleCtrlW
    clc
    jsr renderCursor
    ldz #EDITFILE::rowOff
    nop
    lda (currentFile),z
    clc
    adc #1
    nop
    sta (currentFile),z
    sta intOp2
    inz
    nop
    lda (currentFile),z
    adc #0
    nop
    sta (currentFile),z
    sta intOp2+1
    ldz #EDITFILE::cy
    nop
    lda (currentFile),z
    sta intOp1
    inz
    nop
    lda (currentFile),z
    sta intOp1+1
    jsr ltInt16
    beq :+
    lda intOp2+1
    nop
    sta (currentFile),z
    dez
    lda intOp2
    nop
    sta (currentFile),z
:   jsr editorSetAllRowsDirty
    rts
.endproc

; This routine handles the user pressing CTRL+X
; which exits the editor. It checks for any unsaved files
; and prompts the user if they want to exit anyway.
.proc editorHandleCtrlX
    jsr editorAnyUnsavedFiles
    beq :+
    jsr editorPromptUnsavedFiles
    beq :+
    rts
:   lda #EDITOR_LOOP_QUIT
    sta loopCode
    rts
.endproc

; This routine handles the user pressing CTRL+Y
; which begins a text selection.
.proc editorHandleCtrlY
    ; First, we want to close out any open gap buffer
    jsr closeGapBuf
    jsr startTextSelection
    jsr editorCalcSelection
    rts
.endproc

; This routine handles the user saving the file.
; It saves to an existing file if the filename is set.
; If not, it prompts for the filename.
; If the user elects not to provide a filename, the carry flag
; is cleared on exit. In all other cases, the carry flag is set.
.proc editorHandleFileSave
    ldq currentFile
    jsr isQZero
    beq DN
    ldz #EDITFILE::dirty
    nop
    lda (currentFile),z
    beq DN
    jsr closeGapBuf
    ; See if a filename has been set
    ldz #EDITFILE::filename
    nop
    lda (currentFile),z
    beq editorHandleFileSaveAs
    jsr saveToExisting
    ldz #EDITFILE::dirty
    lda #0
    nop
    sta (currentFile),z
    jsr updateStatusBarFilename
    jsr editorSetDefaultStatusMessage
DN: sec
    rts
.endproc

; This routine is handles save-as.
; On return, the carry flag is set if the file
; was saved. It is cleared if the user did not
; enter a valid filename.
.proc editorHandleFileSaveAs
    ldq currentFile
    jsr isQZero
    beq DN
    jsr closeGapBuf
    jsr fileSaveAs
    sta tmp1
    bcs :+
    rts
    ; Copy the filename
:   ldx #0
    ldz #EDITFILE::filename
:   lda fnBuf,x
    nop
    sta (currentFile),z
    inz
    inx
    cpx tmp1
    bne :-
    lda #0
    nop
    sta (currentFile),z
    ldz #EDITFILE::dirty
    lda #0
    nop
    sta (currentFile),z
    jsr updateStatusBarFilename
    jsr editorSetDefaultStatusMessage
DN: sec
    rts
.endproc

.proc editorHandleRunAndCompile
    pha             ; Save the keystroke

    ; See if a file is currently open
    ldq currentFile
    jsr isQZero
    bne L1
    pla
    rts

L1: ; See if the file is read-only (the help file)
    ldz #EDITFILE::readOnly
    nop
    lda (currentFile),z
    beq L2
    pla
    rts

L2: jsr closeGapBuf
    jsr editorSaveAllFiles
    jsr editorAnyUnsavedFiles
    beq L3
    pla
    rts

L3: jsr editorSaveState
    pla
    cmp #CH_F5 ; run
    bne L4
    sec
    bra L5
L4: clc
L5: jmp runCompiler
.endproc

; This routine is called to handle keystrokes that are special
; while a text selection is active. If the key was handled,
; the carry flag is set on return. Otherwise, the carry flag is
; cleared and the keystroke is handled normally.
.proc editorHandleSelectionKeys
    sta tmp1            ; Save the keystroke

    ; Is a file currently open?
    ldq currentFile
    jsr isQZero
    beq NO

    ; Is a selection active?
    ldz #EDITFILE::inSelection
    nop
    lda (currentFile),z
    beq NO

    lda tmp1            ; Restore the keystroke
    cmp #CH_BACKSPACE
    bne :+
    jsr editorDeleteSelection
    bra CL

:   cmp #CH_BACKARROW
    beq CL

    ora #$80
    cmp #'C'
    bne :+
    jsr editorCopySelection
    bra CL

:   ; Is the file read only?
    ldz #EDITFILE::readOnly
    nop
    lda (currentFile),z
    bne NO

    lda tmp1
    ora #$80
    cmp #'X'
    bne :+
    jsr editorCopySelection
    jsr editorDeleteSelection

CL: jsr editorClearSelection

:   sec
    rts

NO: lda tmp1
    clc
    rts
.endproc

; This routine prompts the user with a message of unsaved files
; and asks them if want to exit anyway. If the user wants to exit
; without saving, the Z flag is set. Otherwise it is cleared.
.proc editorPromptUnsavedFiles
    lda #<promptUnsavedFiles
    ldx #>promptUnsavedFiles
    jsr editorSetStatusMsg
    jsr editorRefreshScreen
L1: jsr editorReadKey
    ora #$80
    cmp #'Y'
    beq YS
    cmp #'N'
    beq NO
    bra L1
NO: jsr editorSetDefaultStatusMessage
    lda #1
YS: rts
.endproc

; This routine saves all files that have filenames.
.proc editorSaveAllFiles
    ; Preserve the currentFile
    ldq currentFile
    pha
    phx
    phy
    phz
    
    ldq firstFile
    stq ptr1

L1: ldq ptr1
    jsr isQZero
    beq L3

    ldz #EDITFILE::dirty
    nop
    lda (ptr1),z
    beq L2
    ; Does the file have a filename?
    ldz #EDITFILE::filename
    nop
    lda (ptr1),z
    beq L2
    ; Save the file
    ldq ptr1
    stq currentFile
    jsr saveToExisting
    ldz #EDITFILE::dirty
    lda #0
    nop
    sta (currentFile),z
    ; Put currentFile back into ptr1
    ldq currentFile
    stq ptr1

L2: ldz #EDITFILE::nextFile
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    bra L1

L3: ; Restore currentFile
    plz
    ply
    plx
    pla
    stq currentFile
    rts
.endproc

; This routine sets the dirty flag for all lines in the current file
.proc editorSetAllRowsDirty
    ; Check if a file is currently open
    ldq currentFile
    jsr isQZero
    beq DN
    lda #1
    sta anyDirtyRows
    ldz #EDITFILE::firstLine
    neg
    neg
    nop
    lda (currentFile),z
    neg
    neg
    sta ptr1
L1: ldq ptr1
    jsr isQZero
    beq DN
    ldz #EDITLINE::dirty
    lda #1
    nop
    sta (ptr1),z
    ldz #EDITLINE::next
    neg
    neg
    nop
    lda (ptr1),z
    neg
    neg
    sta ptr1
    jmp L1
DN: rts
.endproc

.proc editorSetStatusMsg
    sta ptr1
    stx ptr1+1

    ldy #0
:   lda (ptr1),y
    sta statusmsg,y
    beq :+
    iny
    bne :-
:   lda #1
    sta statusmsg_dirty
    rts
.endproc

.proc editorSetDefaultStatusMessage
    lda #<defaultStatusMsg
    ldx #>defaultStatusMsg
    jsr editorSetStatusMsg
    rts
.endproc

; This routine allocates an EDITFILE structure, clears it,
; and stores the pointer in currentFile.
.proc initFile
    lda #.sizeof(EDITFILE)
    ldx #0
    jsr heapAlloc
    neg
    neg
    sta currentFile
    ; Clear the file memory
    lda #0
    ldz #.sizeof(EDITFILE)-1
:   nop
    sta (currentFile),z
    dez
    bpl :-
    rts
.endproc

; This routine checks if a file is currently open
; If so, the carry flag is set.
; A is preserved
.proc isFileOpen
    pha             ; Save the accumulator
    ldq currentFile
    jsr isQZero
    beq NO
    pla
    sec
    rts
NO: pla
    clc
    rts
.endproc

; This routine checks if the current file is open read-only.
; If so, it sets the carry flag. If not, the carry flag is cleared.
; A is preserved, X and Z are destroyed.
.proc isReadOnly
    ldz #EDITFILE::readOnly
    bra checkFileFlag
.endproc

; This routine checks if the current file is dirty (modified).
; If so, it sets the carry flag. If not, the carry flag is cleared.
; A is preserved, X and Z are destroyed.
.proc isDirty
    ldz #EDITFILE::dirty
    ; Fall through to checkFileFlag
.endproc

; This routine checks a file's flag. If the flag is non-zero, the
; carry flag is set. Otherwise it is cleared.
; Z contains index of flag in EDITFILE structure.
; A is preserved, X and Z are destroyed.
.proc checkFileFlag
    tax                             ; Save the keystroke in X
    clc                             ; Assume flag is not set
    nop
    lda (currentFile),z
    beq :+                          ; Branch if not not set
    sec                             ; Set the carry flag (flag is set)
:   txa                             ; Copy the keystroke back to A
    rts
.endproc

.proc isQZero
    cmp #0
    bne :+
    cpx #0
    bne :+
    cpy #0
    bne :+
    cpz #0
:   rts
.endproc

.proc updateStatusBarFilename
    neg
    neg
    lda currentFile
    jsr isQZero
    bne L1
    ; No file currently open
    ldx #0
:   lda welcomeMsg,x    ; Copy the welcome message
    beq :+
    sta statusbar,x
    inx
    bne :-
:   lda #' '            ; Fill the rest with spaces
    sta statusbar,x
    inx
    cpx screencols
    bne :-
    rts
L1: neg
    neg
    sta ptr1            ; currentFile in ptr1
    ldz #EDITFILE::filename
    ldx #0
    nop
    lda (ptr1),z        ; load the first character
    beq L2              ; no filename
:   nop
    lda (ptr1),z
    beq L3
    sta statusbar,x
    inx
    inz
    bne :-
L2: lda nofilename,x
    beq L4
    sta statusbar,x
    inx
    bne L2
L3: ldz #EDITFILE::dirty
    nop
    lda (ptr1),z
    beq L4
    lda #'*'
    sta statusbar,x
    inx
L4: lda #' '
:   cpx #18
    beq :+
    sta statusbar,x
    inx
    bne :-
:   jsr isReadOnly
    bcs L5
    ; File is not read-only
    ldy #3
    lda #' '
    ldx #STATUSCOL_RO
:   sta statusbar,x
    inx
    dey
    bne :-
    beq L6
L5: ; File is read-only
    ldy #0
    ldx #STATUSCOL_RO
:   lda readonlymsg,y
    beq L6
    sta statusbar,x
    inx
    iny
    bne :-
L6: ldx #STATUSCOL_X_LABEL
    ldy #0
:   lda colLabel,y
    beq L7
    sta statusbar,x
    inx
    iny
    bne :-
L7: ldx #STATUSCOL_Y_LABEL
    ldy #0
:   lda rowLabel,y
    beq :+
    sta statusbar,x
    inx
    iny
    bne :-
:   rts
.endproc

; This routine adds the file pointer in currentFile to the linked list
; of open files, stored in firstFile.
.proc addCurrentFile
    ; Check if firstFile is null
    ldq firstFile
    jsr isQZero
    bne L1              ; Branch if not null
    ; firstFile is null, so store currentFile there and exit
    ldq currentFile
    stq firstFile
    rts
    ; Walk the linked list of files and add currentFile to the end.
L1: stq ptr1
    ldz #EDITFILE::nextFile
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero         ; Is the next file null?
    bne L1              ; Branch if not
    ; The next file is null, so set current file and exit.
    ldz #EDITFILE::nextFile+3
    ldx #3
:   lda currentFile,x
    nop
    sta (ptr1),z
    dez
    dex
    bpl :-
    rts
.endproc
