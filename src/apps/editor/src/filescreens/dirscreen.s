;
; dirscreen.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Directory screen routines

.include "zeropage.inc"
.include "editor.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"
.include "asmlib.inc"

.export showDirScreen, showAllFiles, drawHorizLine

.import renderCursor, clearScreen, rowPtrs, petsciiToScreenCode, screencols
.import isQZero, editorReadKey, readDiskDir
.import freeDirEnts, fnBuf, openFile
.import editorDrawMessageBar, statusmsg, statusmsg_dirty, scratchFile
.import inputBufUsed, renameFile, screenrows, calcScreenPtr
.import editorSetAllRowsDirty, editorSetDefaultStatusMessage, anyDirtyRows

PROMPT_ROW = 22

.bss

inputBuf: .res 20
intBuf: .res 7
dirPtr: .res 4              ; temporary pointer
allFiles: .res 4            ; pointer to linked list of DIRENTs
fileInTopRow: .res 2        ; index of file in top left row
selectedFile: .res 2        ; index of selected file
statusRow: .res 20          ; contents of status row
inRightCol: .res 1          ; non-zero if the selection is in the second column
showAllFiles: .res 1        ; non-zero if all files are being shown
dirRows: .res 1             ; number of rows to show on directory screen

.data

prompt1: .asciiz "RETURN: Open  R: Rename  S: Scratch (delete)"
prompt2: .asciiz "Q: Hide non-SEQ files  *: Show all files"
prompt3: .byte $5f, ": Return to editor", $0
fileStr: .asciiz " file"
foundStr: .asciiz " found"
deletePrompt1: .asciiz "    Delete "
deletePrompt2: .asciiz ". Are you sure Y/N?"
renamePrompt: .asciiz "    New filename: "
renamePromptLength:

.code

; This routine locates the address of the first directory entry
; in the first column.
;
; Address returned in Q.
.proc calcFirstEntry
    lda #0
    sta tmp1                ; tmp1/tmp2 = current file number
    sta tmp2
    ldq allFiles
    stq ptr1
L1: ; Is tmp1/tmp2 == fileInTopRow?
    lda fileInTopRow
    cmp tmp1
    bne L2
    lda fileInTopRow+1
    cmp tmp2
    bne L2
    ; tmp1/tmp2 == fileInTopRow
    ldq ptr1
    rts
L2: ; Increment tmp1/tmp2 and move to the next file
    inw tmp1
    ldz #DIRENT::next
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    jmp L1
.endproc

; This routine counts the number of files in the DIRENT
; linked-list in ptr1.
; The number of files is stored in intOp2
.proc calcNumFiles
    lda #0
    sta intOp2
    sta intOp2+1
    ldq ptr1
L1: jsr isQZero
    beq DN
    inw intOp2
    ldz #DIRENT::next
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    jmp L1
DN: rts
.endproc

; This routine clears a directory entry
; Row number is in tmp1
; First screen column in tmp2
.proc clearEntry
    ldy tmp1
    jsr calcScreenPtr
    ldz tmp2
    ldx #33
    lda #' '
:   nop
    sta (ptr4),z
    inz
    dex
    bne :-
    rts
.endproc

.proc clearPromptArea
    ldy screenrows
    dey
    jsr calcScreenPtr
    lda #3
    sta tmp1
    lda screencols
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3

L1: lda #' '
    jsr petsciiToScreenCode
    ldx screencols
    ldz #0
:   nop
    sta (ptr4),z
    inz
    dex
    bne :-

    ldq ptr4
    clc
    adcq intOp32
    stq ptr4

    dec tmp1
    bne L1

    rts
.endproc

; This routine renders a directory entry
; Row number is in tmp1
; First screen column in tmp2
; Directory entry is in ptr1
.proc drawEntry
    ldy tmp1
    jsr calcScreenPtr
    ldq ptr4
    stq ptr2
    ldz tmp2

    ; Is the file selected?
    lda #0
    sta tmp3                    ; row highlight mask
    lda intOp1
    cmp selectedFile
    bne :+                      ; branch if low byte not equal
    lda intOp1+1
    cmp selectedFile+1
    bne :+                      ; branch if high byte not equal
    lda #$80
    sta tmp3                    ; turn on highlight

    ; Draw the first two spaces
:   lda #' '
    jsr petsciiToScreenCode
    ora tmp3
    nop
    sta (ptr2),z
    inz
    nop
    sta (ptr2),z
    inz
    stz tmp4

    ; Render the blocks
    ldz #DIRENT::blocks
    ldx #0
:   nop
    lda (ptr1),z
    jsr petsciiToScreenCode
    ora tmp3                    ; highlight if selected
    phz
    ldz tmp4
    nop
    sta (ptr2),z
    plz
    inx
    inc tmp4
    inz
    cpx #3
    bne :-
    ; Pad with 3 more spaces
    lda #' '
    jsr petsciiToScreenCode
    ora tmp3                    ; highlight if selected
    ldz tmp4
    nop
    sta (ptr2),z
    inz
    nop
    sta (ptr2),z
    inz
    nop
    sta (ptr2),z
    inz
    stz tmp4
    ldz #DIRENT::filename
:   nop
    lda (ptr1),z
    jsr petsciiToScreenCode
    ora tmp3                    ; highlight if selected
    phz
    ldz tmp4
    nop
    sta (ptr2),z
    plz
    inz
    inc tmp4
    cpz #16
    bne :-
    ; Draw two spaces
    lda #' '
    jsr petsciiToScreenCode
    ora tmp3                    ; highlight if selected
    ldz tmp4
    nop
    sta (ptr2),z
    inz
    nop
    sta (ptr2),z
    inz
    stz tmp4
    ; Draw the file type
    ldz #DIRENT::type
    ldx #2
:   nop
    lda (ptr1),z
    jsr petsciiToScreenCode
    ora tmp3                    ; highlight if selected
    phz
    ldz tmp4
    nop
    sta (ptr2),z
    inz
    stz tmp4
    plz
    inz
    dex
    bpl :-

    ; Render four more spaces
    ldx #4
    lda #' '
    jsr petsciiToScreenCode
    ora tmp3
    ldz tmp4
:   nop
    sta (ptr2),z
    inz
    dex
    bne :-
    
    rts
.endproc

; Draws a horizontal line on the screen
;    ptr1 points to screen row
;    Z register contains starting column number
;    X register contains number of characters to draw
.proc drawHorizLine
    lda #CH_HORIZ_LINE
:   nop
    sta (ptr1),z
    inz
    dex
    bne :-
    rts
.endproc

.proc drawPromptArea
    jsr clearPromptArea

    ldy screenrows
    dey
    jsr calcScreenPtr
    lda #<prompt1
    ldx #>prompt1
    jsr drawPromptRow

    ldy screenrows
    jsr calcScreenPtr
    lda #<prompt2
    ldx #>prompt2
    jsr drawPromptRow

    ldy screenrows
    iny
    jsr calcScreenPtr
    sta ptr1+1
    lda #<prompt3
    ldx #>prompt3
    jsr drawPromptRow

    rts
.endproc

; This routine draws a row in the prompt area
;    ptr4 - points to row in screen RAM
;    A/X - points to NULL-terminated PETSCII string to draw
.proc drawPromptRow
    sta ptr2
    stx ptr2+1

    ; Add 4 to ptr1 (start in the 4th column)
    lda #4
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq ptr4
    clc
    adcq intOp32
    stq ptr4

    ldz #0
:   lda (ptr2),z
    beq :+
    jsr petsciiToScreenCode
    nop
    sta (ptr4),z
    inz
    bne :-
:   rts
.endproc

.proc fillDirEnts
    jsr resetSelection
    ldq allFiles
    jsr isQZero
    beq :+
    jsr freeDirEnts
:   jsr readDiskDir
    stq allFiles
    stq ptr1
    jsr calcNumFiles
    jsr showDirectory
    jsr updateStatusRow
    rts
.endproc

; This routine gets a pointer to the DIRENT structure
; for the selected file. ptr1 contains the pointer.
.proc getSelectedFile
    lda #0
    sta intOp1
    sta intOp2
    lda selectedFile
    sta intOp2
    lda selectedFile+1
    sta intOp2+1
    ; ptr1 is the current file
    ldq allFiles
    stq ptr1
:   jsr eqInt16
    bne :+
    ; Move to the next file
    ldz #DIRENT::next
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    inw intOp1
    bra :-
:   rts
.endproc

.proc processKeypress
L1: jsr editorReadKey
    cmp #CH_ENTER
    bne :+
    jmp processEnter
:   cmp #CH_CURS_DOWN
    bne :+
    jsr processCursorDown
    jmp L1
:   cmp #CH_CURS_UP
    bne :+
    jsr processCursorUp
    jmp L1
:   cmp #CH_CURS_LEFT
    bne :+
    jsr processCursorLeft
    jmp L1
:   cmp #CH_CURS_RIGHT
    bne :+
    jsr processCursorRight
    jmp L1
:   cmp #'*'
    bne :+
    lda #1
    sta showAllFiles
    jsr fillDirEnts
    jmp L1
:   cmp #'q'
    bne :+
    lda #0
    sta showAllFiles
    jsr fillDirEnts
    jmp L1
:   cmp #'s'
    bne :+
    jsr processScratchFile
    jmp L1
:   cmp #'r'
    bne :+
    jsr processRenameFile
    jmp L1
:   cmp #CH_BACKARROW
    bne :+
    rts
:   jmp L1
.endproc

.proc processCursorDown
    lda intOp2
    ora intOp2+1
    bne L1
    rts

L1: ; Is selectedFile+1 >= numFiles?
    lda selectedFile
    sta intOp1
    lda selectedFile+1
    sta intOp1+1
    inw intOp1
    jsr geInt16
    beq L2
    rts

L2: ; Is the cursor in the right column?
    lda inRightCol
    beq L4
    ; If the selection is at the bottom and there are more rows,
    ; scroll the list up
    ; Calculate fileInTopRow + dirRows*2 - 1
    ; and store it in intOp1
    lda dirRows
    asl a
    sta tmp1
    dec tmp1
    lda fileInTopRow
    clc
    adc tmp1
    sta intOp1
    lda fileInTopRow+1
    adc #0
    sta intOp1+1
    lda selectedFile
    cmp intOp1
    bne L9
    lda selectedFile+1
    cmp intOp1+1
    bne L9
    ; Is it less than numFiles (intOp2)
    jsr ltInt16
    beq L9
    ; Increment fileInTopRow
    lda fileInTopRow
    clc
    adc #1
    sta fileInTopRow
    lda fileInTopRow+1
    adc #0
    sta fileInTopRow+1
    jmp L9

L4: ; Calculate fileInTopRow + dirRows - 1
    lda fileInTopRow
    clc
    adc dirRows
    sta intOp1
    dec intOp1
    lda fileInTopRow+1
    adc #0
    sta intOp1+1
    ; Is it equal to selectedFile?
    lda intOp1
    cmp selectedFile
    bne L9
    lda intOp1+1
    cmp selectedFile+1
    bne L9
    ; Selected file is last row if display.
    ; If there is a file in the right column, move to the top of the right column
    jsr ltInt16
    bne L5
    rts
    ; Move to the top of the right column
L5: lda #1
    sta inRightCol
    jmp L9

L9:
    lda selectedFile
    clc
    adc #1
    sta selectedFile
    lda selectedFile+1
    adc #0
    sta selectedFile+1
    jsr showDirectory
    rts
.endproc

.proc processCursorLeft
    lda intOp2
    ora intOp2+1
    bne :+
    rts
:   lda inRightCol
    bne :+
    rts
:   lda selectedFile
    sec
    sbc dirRows
    sta selectedFile
    lda selectedFile+1
    sbc #0
    sta selectedFile+1
    lda #0
    sta inRightCol
    jmp showDirectory
.endproc

.proc processCursorRight
    lda intOp2
    ora intOp2+1
    bne :+
    rts
:   lda inRightCol
    beq :+
    rts
:   lda selectedFile
    clc
    adc dirRows
    sta intOp1
    lda selectedFile+1
    adc #0
    sta intOp1+1
    jsr geInt16
    beq :+
    rts
:   lda intOp1
    sta selectedFile
    lda intOp1+1
    sta selectedFile+1
    lda #1
    sta inRightCol
    jmp showDirectory
.endproc

.proc processCursorUp
    lda intOp2
    ora intOp2+1
    bne L1
    rts

    ; If in the right column and already at the top,
    ; move the selected to bottom of the left column
L1: lda inRightCol
    beq L2
    lda fileInTopRow
    bne L2
    lda fileInTopRow+1
    bne L2
    lda selectedFile
    cmp dirRows
    bne L2
    lda selectedFile+1
    bne L2
    ; Move the cursor to the bottom of the left column
    lda #0
    sta inRightCol
    lda dirRows
    sec
    sbc #1
    sta selectedFile
    lda #0
    sta selectedFile+1
    jsr showDirectory
    rts

    ; If the selection is already on the first file, ignore the cursor
L2: lda selectedFile
    ora selectedFile+1
    bne L3
    rts

    ; Is the selection in the top row?
L3: lda selectedFile
    cmp fileInTopRow
    bne L4
    lda selectedFile+1
    cmp fileInTopRow+1
    beq L5
    ; Is the cursor on the right side?
L4: lda inRightCol
    beq L6
    ; Calculate file number of top file on the right side
    lda fileInTopRow
    clc
    adc dirRows
    sta tmp1
    lda fileInTopRow+1
    adc #0
    sta tmp2
    ; Is selectedFile == fileInTopRow + dirRows
    lda selectedFile
    cmp tmp1
    bne L6
    lda selectedFile+1
    cmp tmp2
    bne L6
L5: ; Cursor is in top row, move the selection up one row
    ; and decrement the fileInTopRow
    lda fileInTopRow
    sec
    sbc #1
    sta fileInTopRow
    lda fileInTopRow+1
    sbc #0
    sta fileInTopRow+1
    lda selectedFile
    sec
    sbc #1
    sta selectedFile
    lda selectedFile+1
    sbc #0
    sta selectedFile+1
    jsr showDirectory
    rts
L6: lda selectedFile
    sec
    sbc #1
    sta selectedFile
    lda selectedFile+1
    sbc #0
    sta selectedFile+1
    jsr showDirectory
    rts
.endproc

; This routine is called when the user hits Enter on a file
.proc processEnter
    ; First, get the filename of the selected file.
    jsr getSelectedFile
    ; Copy the filename to fnBuf
    ldz #DIRENT::filename
    ldx #0
:   nop
    lda (ptr1),z
    sta fnBuf,x
    inx
    cpx #16                 ; End of filename?
    beq :+
    inz
    bne :-
:   ; The filename in DIRENT is space-filled, not null-terminated.
    ; Need to right-trim and null-terminate the filename.
    dex
:   lda fnBuf,x
    cmp #' '
    bne :+
    dex
    bne :-
:   lda #0
    inx
    sta fnBuf,x
    ; Open the file
    jsr openFile
    ; Clear the keyboard buffer
:   jsr GETIN
    bne :-
    ; Go back to the editor screen
    rts
.endproc

.proc processRenameFile
    jsr clearPromptArea
    ; Copy the rename prompt
    ldy #0
    ldx #0
:   lda renamePrompt,y
    beq :+
    sta statusmsg,x
    inx
    iny
    bne :-
:   lda #0
    sta statusmsg,x
    lda #1
    sta statusmsg_dirty
    jsr editorDrawMessageBar
    ; Move the cursor because getline uses CHROUT
    ldy #renamePromptLength-renamePrompt-1
    ldx screenrows
    inx
    clc
    jsr PLOT
    ; Call getline
    lda #<inputBuf
    ldx #>inputBuf
    jsr getline
    sta tmp1
    bcc DN              ; Branch if the user hit esc
    beq DN              ; Branch if the user hit enter with a blank name
    ; Zero-terminate the inputBuf
    lda #0
    ldx tmp1
    sta inputBuf,x
    ; Copy the selected filename to fnBuf
    jsr getSelectedFile
    ldz #DIRENT::filename
    ldx #0
:   nop
    lda (ptr1),z
    sta fnBuf,x
    inz
    inx
    cpx #16
    bne :-
    ; Right-trim the filename
    dex
:   lda fnBuf,x
    cmp #' '
    bne :+
    dex
    bra :-
:   inx
    lda #0
    sta fnBuf,x
    ; Pointer to fnBuf in ptr1
    lda #<fnBuf
    sta ptr1
    lda #>fnBuf
    sta ptr1+1
    ; Pointer to inputBuf in ptr2
    lda #<inputBuf
    sta ptr2
    lda #>inputBuf
    sta ptr2+1
    lda #0
    sta ptr1+2
    sta ptr1+3
    sta ptr2+2
    sta ptr2+3
    jsr renameFile
    jsr fillDirEnts
DN: jsr drawPromptArea
    rts
.endproc

.proc processScratchFile
    jsr clearPromptArea
    jsr getSelectedFile
    ; Copy the first part of the prompt
    ldy #0
    ldx #0
:   lda deletePrompt1,y
    beq :+
    sta statusmsg,x
    inx
    iny
    bne :-
    ; Copy the filename
:   ldz #DIRENT::filename
    ldy #0
    ; The filename in DIRENT is space-filled to 16 characters.
    ; The entire filename is copied then right-trimmed before
    ; copying the rest of the prompt.
:   nop
    lda (ptr1),z
    sta statusmsg,x
    sta fnBuf,y
    inx
    iny
    inz
    cpy #16
    bne :-
    dex
:   lda statusmsg,x
    cmp #' '
    bne :+
    dex
    dey
    bne :-
:   ; Put a zero at the end of fnBuf
    lda #0
    sta fnBuf,y
    ; Copy the rest of the prompt
    ldy #0
    inx
:   lda deletePrompt2,y
    sta statusmsg,x
    beq :+
    inx
    iny
    bne :-
:   lda #1
    sta statusmsg_dirty
    jsr editorDrawMessageBar
L1: jsr editorReadKey
    ora #$80
    cmp #'N'
    beq DN
    cmp #'Y'
    bne L1
    ; User answered yes.
    lda #<fnBuf
    sta ptr1
    lda #>fnBuf
    sta ptr1+1
    lda #0
    sta ptr1+2
    sta ptr1+3
    jsr scratchFile
    jsr fillDirEnts
DN: jsr drawPromptArea
    rts
.endproc

.proc resetSelection
    lda #0
    sta fileInTopRow
    sta fileInTopRow+1
    sta selectedFile
    sta selectedFile+1
    sta inRightCol
    rts
.endproc

; This routine shows a directory, stored in a DIRENT linked-list.
.proc showDirectory
    jsr calcFirstEntry
    stq dirPtr              ; Store directory list in dirPtr
    stq ptr1                ; and ptr1
    lda fileInTopRow        ; Start at fileInTopRow
    sta intOp1
    lda fileInTopRow+1
    sta intOp1+1
    lda #5
    sta tmp2
    ldq dirPtr
    stq ptr1
    jsr showDirectorySide
    lda #39
    sta tmp2
    jsr showDirectorySide
    rts
.endproc

; This routine shows a directory in either the left or right pane.
; The column is in tmp2.
; The linked list is in ptr1.
; intOp1 contains the file number
.proc showDirectorySide
    lda #1
    sta tmp1                ; Row number in tmp1
L1: lda tmp1
    sec
    sbc #1
    cmp dirRows             ; Is row number < dirRows
    beq DN                  ; Branch if row number >= dirRows
    jsr geInt16             ; Is file number >= num files
    beq L2
    jsr clearEntry
    jmp L3
L2: jsr drawEntry
L3: ldz #DIRENT::next
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L4
    stq ptr1
L4: inw intOp1
    inc tmp1
    bne L1
DN: rts
.endproc

.proc showDirScreen
    clc
    jsr renderCursor        ; Clear the cursor
    jsr clearScreen

    ; Calculate the number of directory rows to show on the screen
    lda screenrows
    sec
    sbc #6
    sta dirRows

    ; Draw the first row
    ldq rowPtrs
    stq ptr1
    lda #CH_UL_CORNER
    ldz #4
    nop
    sta (ptr1),z
    inz
    ldx #33
    jsr drawHorizLine
    lda #CH_UPPER_TEE
    nop
    sta (ptr1),z
    inz
    ldx #33
    jsr drawHorizLine
    lda #CH_UR_CORNER
    nop
    sta (ptr1),z
    inz

    ; Draw vertical lines
    lda dirRows
    sta tmp1                    ; Use tmp1 as a counter
    lda #1
    sta tmp2                    ; Use tmp2 as a row number
:   ldy tmp2
    jsr calcScreenPtr
    ldq ptr4
    stq ptr1
    lda #CH_VERT_LINE
    ldz #4
    nop
    sta (ptr1),z
    ldz #38
    nop
    sta (ptr1),z
    ldz #72
    nop
    sta (ptr1),z
    inc tmp2
    dec tmp1
    bne :-

    ; Draw a horizontal line
    ldy tmp2
    jsr calcScreenPtr
    ldq ptr4
    stq ptr1
    lda #CH_LEFT_TEE
    ldz #4
    nop
    sta (ptr1),z
    inz
    ldx #33
    jsr drawHorizLine
    lda #CH_BOTTOM_TEE
    nop
    sta (ptr1),z
    inz
    ldx #33
    jsr drawHorizLine
    lda #CH_RIGHT_TEE
    nop
    sta (ptr1),z
    inc tmp2

    ; Draw an empty line with size borders
    ldy tmp2
    jsr calcScreenPtr
    ldz #4
    lda #CH_VERT_LINE
    nop
    sta (ptr4),z
    ldz #72
    nop
    sta (ptr4),z
    inc tmp2

    ; Draw the bottom horizontal line
    ldy tmp2
    jsr calcScreenPtr
    ldq ptr4
    stq ptr1
    ldz #4
    lda #CH_LL_CORNER
    nop
    sta (ptr1),z
    inz
    ldx #67
    jsr drawHorizLine
    lda #CH_LR_CORNER
    nop
    sta (ptr1),z
    inc tmp2

    jsr drawPromptArea

    jsr resetSelection

    lda #0
    sta showAllFiles
    tax
    tay
    taz
    stq allFiles

    jsr fillDirEnts

    jsr processKeypress

    ldq allFiles
    jsr freeDirEnts

    jsr editorSetDefaultStatusMessage
    jsr editorSetAllRowsDirty
    lda #1
    sta anyDirtyRows
    jsr clearScreen

    rts
.endproc

.proc updateStatusRow
    ; dirRows+2
    lda intOp2
    sta intOp1
    pha                 ; Save intOp2
    ldx intOp2+1
    stx intOp1+1
    phx                 ; Since writeInt16 destroys it
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    ; Restore intOp2
    pla
    sta intOp2+1
    pla
    sta intOp2

    ; Put number of files in status msg
    ldx #0
    ldy #0
:   lda intBuf,x
    beq L1
    sta statusRow,y
    inx
    iny
    bne :-

    ; Add " file"
L1: ldx #0
:   lda fileStr,x
    beq L2
    sta statusRow,y
    inx
    iny
    bne :-

    ; Add "s" if intOp2 != 1
L2: lda intOp2
    cmp #1
    bne AS
    lda intOp2+1
    beq L3
AS: lda #'s'
    sta statusRow,y
    iny

    ; Add " found"
L3: ldx #0
:   lda foundStr,x
    beq L4
    sta statusRow,y
    inx
    iny
    bne :-

    ; Add a null terminator
L4: lda #0
    sta statusRow,y

    tya                 ; Number of characters
    lsr a               ; Divide by 2 to center
    sta tmp1
    lda #38
    sec
    sbc tmp1            ; Subtract from 38 (center of status area)
    sta tmp1            ; Save starting column in tmp1

    lda dirRows
    clc
    adc #2
    tay
    jsr calcScreenPtr
    ldq ptr4
    stq ptr1

    ; Clear the status row first
    lda screencols
    sec
    sbc #13
    tax
    ldz #5
    lda #' '
    jsr petsciiToScreenCode
:   nop
    sta (ptr1),z
    inz
    dex
    bne :-

    ; Draw the status message

    ldx #0
    ldz tmp1
:   lda statusRow,x
    beq :+
    jsr petsciiToScreenCode
    nop
    sta (ptr1),z
    inz
    inx
    bne :-

:   rts
.endproc
