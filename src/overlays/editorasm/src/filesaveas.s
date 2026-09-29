;
; filesaveas.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; fileSaveAs routine

.include "cbm_kernal.inc"
.include "c64.inc"
.include "4510macros.inc"
.include "zeropage.inc"
.include "asmlib.inc"
.include "editor.inc"

.export fileSaveAs

.import screenrows, fnBuf
.import editorDrawMessageBar, statusmsg, statusmsg_dirty
.import fileWrite, renderCursor, setIsPascal, editorSetAllRowsDirty
.import editorReadKey, editorSetStatusMsg, editorSetDefaultStatusMessage
.import editorRefreshScreen, syntaxHighlight, anyDirtyRows

.data

saveAsPrompt: .asciiz "Save As: "
saveAsPromptLength:
overwritePrompt: .asciiz " already exists. Overwrite Y/N?"

.bss

inputBufUsed: .res 1
currentLine: .res 4
multilineCommentCarry: .res 1

.code

; This routine prompts the user for a filename.
; If the pressed escape or entered a blank filename,
; the carry flag is cleared. Otherwise, it is set.
; The filename is stored in fnBuf and the number of characters is returned in A.
.proc fileSaveAs
    ; Copy saveAsPrompt to statusmsg
    lda #<saveAsPrompt
    ldx #>saveAsPrompt
    jsr editorSetStatusMsg
    jsr editorDrawMessageBar
    ; Move the cursor because getline uses CHROUT
    ldy #saveAsPromptLength-saveAsPrompt-1
    ldx screenrows
    inx
    clc
    jsr PLOT
    ; Clear the editor cursor
    clc
    jsr renderCursor
    ; Call getline
    lda #<fnBuf
    ldx #>fnBuf
    jsr getline
    sta inputBufUsed
    bcs :+              ; Branch if the user hit enter
    rts
:   bne :+              ; Branch if the user entered a filename
    ; The filename was blank so clear the carry flag and return
    clc
    rts

    ; Check if the filename already exists
:   ldx inputBufUsed
    lda #0
    sta fnBuf,x
    lda #<fnBuf
    ldx #>fnBuf
    ldy #0
    ldz #0
    jsr doesFileExist
    beq L1
    ; The file already exists.
    ; Ask the user if they want to overwrite it.
    jsr askOverwrite
    bcc DN                  ; User is not overwriting - exit
    ; Delete the existing file
    lda #<fnBuf
    ldx #>fnBuf
    ldy #0
    ldz #0
    jsr scratchFile

    ; Call SETLFS
L1: ldx DEVNUM
    lda #1
    tay
    iny
    jsr SETLFS
    ; Set up the filename
    lda #<fnBuf
    ldx #>fnBuf
    ldy #0
    ldz #0
    clc
    jsr makeFilename
    jsr SETNAM
    ; Open the file and set output channel
    jsr OPEN
    ldx #1
    jsr CHKOUT

    ; Write the file contents
    jsr fileWrite

    ; Close the file
    lda #1
    jsr CLOSE
    ldx #0
    jsr CHKOUT

    ; Set the isPascal flag
    jsr setIsPascal

    ; If the file is a Pascal file, the isPascal flag will be set by setIsPascal
    ; and the editor needs to redraw the lines for syntax highlighting.
    ldz #EDITFILE::isPascal
    nop
    lda (currentFile),z
    beq :+
    jsr syntaxHighlightAllRows

:   lda inputBufUsed
    sec
DN: rts
.endproc

; This routine prompts the user to overwrite the file.
; If carry flag is cleared if the user does not want to overwrite.
.proc askOverwrite
    ; Copy the filename to the statusmsg
    ldx #0
    ldy #0
:   lda fnBuf,y
    beq :+
    sta statusmsg,y
    inx
    iny
    bne :-
:   ldx #0
:   lda overwritePrompt,x
    sta statusmsg,y
    beq :+
    inx
    iny
    bne :-
:   lda #1
    sta statusmsg_dirty
    jsr editorDrawMessageBar
L1: jsr editorReadKey
    ora #$80            ; Convert to upper case
    cmp #'N'
    beq NO
    cmp #'Y'
    beq YES
    bra L1
NO: jsr editorSetDefaultStatusMessage
    clc
    rts
YES:
    sec
    rts
.endproc

.proc syntaxHighlightAllRows
    lda #0
    sta multilineCommentCarry

    ldz #EDITFILE::firstLine
    neg
    neg
    nop
    lda (currentFile),z
    stq currentLine

    lda #1
    sta anyDirtyRows

    ; Loop through the rows in the file, running syntax highlighting on each row.
L1: ldq currentLine
    bne L2
    rts

L2: stq ptr3

    ; Make sure a syntax highlight buffer is allocated for the current line.
    jsr ensureSyntaxHighlightBuffer

    ldz #EDITLINE::buffer
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr1
    ldz #EDITLINE::syntaxHL
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr2
    clc
    lda multilineCommentCarry
    beq L3
    sec
L3: ldz #EDITLINE::length
    nop
    lda (ptr3),z
    jsr syntaxHighlight
    lda #0
    bcc L4
    lda #1
L4: sta multilineCommentCarry
    ldq currentLine
    stq ptr3

    lda #1
    ldz #EDITLINE::dirty
    nop
    sta (ptr3),z

    ; Go to the next line
    ldz #EDITLINE::next
    neg
    neg
    nop
    lda (ptr3),z
    stq currentLine
    bra L1
.endproc

; This routine ensures that a syntax highlight buffer is allocated for the current line.
; This routine checks if a syntax highlight buffer exists for the current line.
; If it does not exist, it allocates one. The current line is in ptr3.
.proc ensureSyntaxHighlightBuffer
    ldz #EDITLINE::syntaxHL
    neg
    neg
    nop
    lda (ptr3),z
    jsr isQZero
    beq L1
    rts

L1: ldz #EDITLINE::capacity
    nop
    lda (ptr3),z
    ldx #0
    jsr heapAlloc
    stq ptr1
    ldq currentLine
    stq ptr3
    ldx #0
    ldz #EDITLINE::syntaxHL
:   lda ptr1,x
    nop
    sta (ptr3),z
    inz
    inx
    cpx #4
    bne :-

    rts
.endproc
