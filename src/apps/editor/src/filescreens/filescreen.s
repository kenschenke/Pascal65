;
; filescreen.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; showFileScreen routine

.include "editor.inc"
.include "zeropage.inc"
.include "4510macros.inc"
.include "asmlib.inc"

FILES_PER_PAGE = 9

.export showFileScreen

.import editorSetStatusMsg, editorRefreshScreen, editorReadKey, editorSetDefaultStatusMessage
.import showDirScreen, editorNewFile, drawHorizLine, rowPtrs, clearScreen, renderCursor
.import petsciiToScreenCode, firstFile, isQZero, editorSetAllRowsDirty
.import updateStatusBarFilename, anyDirtyRows, fileClose, editorHandleFileSave
.import editorHandleFileSaveAs, calcScreenPtr, screenrows

.bss

fileCount: .res 1
fileRangeLow: .res 1
fileRangeHigh: .res 1
intBuf: .res 7

.data

fileScreenPrompt: .byte "O=Open, S=Save, A=Save As N=New, C=Close, M=Active Files, $=Dir, ", $5f, "=Back", $0
fileScreenHeader: .asciiz "Open Files (* = Current File)"
footerPrompt1: .asciiz "Type number to switch to file"
footerPrompt2: .byte $5f, "  Return to Editor", $0
filePrompt: .asciiz "file"
openPrompt: .asciiz " open"
noFilesOpen: .asciiz "No files open"
noFilename: .asciiz "No filename"
showingFilesPrompt: .asciiz "Showing files "
arrowsPrompt: .asciiz "Left / right arrows to see more files"
dashPrompt: .asciiz " - "
modifiedStr: .asciiz " (modified)"

.code

.proc showFileScreen
    lda #<fileScreenPrompt
    ldx #>fileScreenPrompt
    jsr editorSetStatusMsg
    jsr editorRefreshScreen
L1: jsr editorReadKey
    cmp #CH_BACKARROW
    bne :+
    jsr editorSetDefaultStatusMessage
    jmp editorRefreshScreen
:   cmp #'$'
    bne :+
    jmp showDirScreen
:   cmp #'n'
    bne :+
    jmp editorNewFile
:   cmp #'o'
    bne :+
    jmp showDirScreen
:   cmp #'m'
    bne :+
    jmp showActiveFiles
:   cmp #'s'
    bne :+
    jsr editorHandleFileSave
    jsr editorSetDefaultStatusMessage
    jmp editorRefreshScreen
:   cmp #'c'
    bne :+
    jsr handleFileClose
    jsr editorSetDefaultStatusMessage
    jmp editorRefreshScreen
:   cmp #'a'
    bne :+
    jsr editorHandleFileSaveAs
    jsr editorSetDefaultStatusMessage
    jmp editorRefreshScreen
:   jmp L1
.endproc

.proc showActiveFiles
    jsr renderFileScreenOutline
    jsr countActiveFiles
    sta fileCount               ; Save count for later
    lda fileCount
    sta intOp1
    lda #0
    sta intOp1+1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16              ; Convert count to PETSCII
    ; Set the low and high file for the first page
    lda #1
    sta fileRangeLow
    lda #FILES_PER_PAGE
    sta fileRangeHigh
    cmp fileCount
    bcc :+
    lda fileCount
    sta fileRangeHigh
:   lda screenrows
    sec
    sbc #9
    tay
    jsr calcScreenPtr
    lda fileCount               ; Any files open?
    bne L0                      ; Branch if so
    ldx #0
    ldz #32
:   lda noFilesOpen,x
    beq L1
    jsr petsciiToScreenCode
    nop
    sta (ptr4),z
    inz
    inx
    bne :-
L0: ldz #32                     ; Write count to screen
    ldx #0
:   lda intBuf,x
    beq :+                      ; Branch if end of count string
    nop
    sta (ptr4),z
    inx
    inz
    bne :-
:   inz
    ; Write the word "file"
    ldx #0
:   lda filePrompt,x
    beq :+
    jsr petsciiToScreenCode
    nop
    sta (ptr4),z
    inx
    inz
    bne :-
    ; Add an "s" if count is != 1
:   lda fileCount
    cmp #1
    beq :+                      ; Branch if count != 1
    lda #'s'
    jsr petsciiToScreenCode
    nop
    sta (ptr4),z
    inz
:   ldx #0
:   lda openPrompt,x
    beq :+
    jsr petsciiToScreenCode
    nop
    sta (ptr4),z
    inx
    inz
    bne :-
    ; If there are more files than will fit on the one page,
    ; show pagination prompts as well
:   lda fileCount
    cmp #FILES_PER_PAGE+1
    bcc L1
    lda screenrows
    sec
    sbc #4
    tay
    jsr calcScreenPtr
    ldx #0
    ldz #3
:   lda arrowsPrompt,x
    beq L1
    jsr petsciiToScreenCode
    nop
    sta (ptr4),z
    inx
    inz
    bne :-
L1: jsr showFilePage
L2: jsr editorReadKey
    cmp #CH_CURS_RIGHT
    bne :+
    jsr handleCursorRight
    bra L1
:   cmp #CH_CURS_LEFT
    bne :+
    jsr handleCursorLeft
    bra L1
:   cmp #'1'
    bcc :+
    cmp #'9'+1
    bcs :+
    jsr handleFileNumberKey
    rts
:   cmp #CH_BACKARROW
    bne :+
    jsr editorSetDefaultStatusMessage
    lda #1
    sta anyDirtyRows
    jsr editorSetAllRowsDirty
    jsr clearScreen
    jmp editorRefreshScreen
:   bra L2
.endproc

.proc handleCursorLeft
    lda fileRangeLow
    cmp #1                  ; Already at the first page?
    beq DN                  ; Branch if so
    sec
    sbc #FILES_PER_PAGE
    sta fileRangeLow
    clc
    adc #FILES_PER_PAGE-1
    sta fileRangeHigh
DN: rts
.endproc

.proc handleCursorRight
    lda fileRangeHigh
    cmp fileCount           ; Already at the last page?
    beq DN                  ; Branch if so
    lda fileRangeLow
    clc
    adc #FILES_PER_PAGE
    sta fileRangeLow
    lda fileRangeHigh
    clc
    adc #FILES_PER_PAGE
    cmp fileCount           ; Is the high range file > file count?
    bcc :+
    lda fileCount
:   sta fileRangeHigh
DN: rts
.endproc

.proc handleFileClose
    ldq currentFile
    jsr isQZero
    beq DN
    clc
    jsr renderCursor
    jsr fileClose
    jsr clearScreen
    lda #1
    sta anyDirtyRows
    jsr editorSetAllRowsDirty
    jsr editorSetDefaultStatusMessage
    jsr updateStatusBarFilename
DN: rts
.endproc

.proc handleFileNumberKey
    sec
    sbc #'1'
    pha
    jsr getFirstFileForPage
    pla
    sta tmp1
:   lda tmp1
    beq L1
    ldz #EDITFILE::nextFile
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    dec tmp1
    bne :-
L1: ldq ptr1
    stq currentFile
    lda #1
    sta anyDirtyRows
    jsr editorSetDefaultStatusMessage
    jsr updateStatusBarFilename
    jsr editorSetAllRowsDirty
    rts
.endproc

; This routine clears the file area
.proc clearFileArea
    lda #4                      ; Start clearing at the 4th row
    sta tmp1                    ; tmp1 is row number
    tax
    lda #FILES_PER_PAGE
    sta tmp2                    ; tmp2 counts the number of rows to clear
L1: ldy tmp1
    jsr calcScreenPtr
    ldx #30                     ; clear 30 columns
    ldz #5                      ; start in 5th column
    lda #' '
L2: nop
    sta (ptr4),z
    inz
    dex
    bne L2
    inc tmp1
    dec tmp2
    bne L1
    rts
.endproc

; This routine renders the files for the current page
.proc showFilePage
    jsr clearFileArea
    lda fileCount
    cmp #FILES_PER_PAGE+1
    bcs :+                      ; Branch if count <= FILES_PER_PAGE
    jmp L0
:   lda screenrows
    sec
    sbc #5
    tay
    jsr calcScreenPtr
    ldx #0
    ldz #3
:   lda showingFilesPrompt,x
    beq :+
    jsr petsciiToScreenCode
    nop
    sta (ptr4),z
    inx
    inz
    bne :-
:   ; Show low and high file numbers
    phz                         ; Save the Y index on the stack
    lda fileRangeLow
    ldx #0
    jsr writeInt16
    lda screenrows
    sec
    sbc #5
    tay
    jsr calcScreenPtr
    ldx #0
    plz
:   lda intBuf,x
    beq :+
    nop
    sta (ptr4),z
    inz
    inx
    bne :-
:   ldx #0
:   lda dashPrompt,x
    beq :+
    nop
    sta (ptr4),z
    inx
    inz
    bne :-
:   lda fileRangeHigh
    ldx #0
    phz
    jsr writeInt16
    lda screenrows
    sec
    sbc #5
    tay
    jsr calcScreenPtr
    ldx #0
    plz
:   lda intBuf,x
    beq :+
    nop
    sta (ptr4),z
    inz
    inx
    bne :-
:   ; Clear a few extra spaces on the row
    ldx #5
    lda #' '
:   nop
    sta (ptr4),z
    inz
    dex
    bne :-

L0: ; Set ptr1 to the first file on the current page
    jsr getFirstFileForPage
    lda #16                      ; Start at 4th row of screen
    sta tmp2                    ; tmp2 is index into rowPtrs
    lda #1
    sta tmp1                    ; tmp1 is file counter for current page
L1: ldq ptr1
    jsr isQZero
    bne :+
    jmp DN
:   ldx tmp2
    lda rowPtrs,x
    sta ptr2                    ; ptr2 is pointer to current row in screen RAM
    lda rowPtrs+1,x
    sta ptr2+1
    lda rowPtrs+2,x
    sta ptr2+2
    lda rowPtrs+3,x
    sta ptr2+3
    ldq currentFile
    cpq ptr1
    bne L2
    ldz #7
    lda #'*'
    nop
    sta (ptr2),z
L2: ldz #9
    lda tmp1
    clc
    adc #'0'
    nop
    sta (ptr2),z
    inz
    lda #':'
    nop
    sta (ptr2),z
    inz
    inz
    stz tmp4                ; screen column index in tmp4
    ldz #EDITFILE::filename
    stz tmp3                ; filename index in tmp3
    ; Check if filename is empty
    nop
    lda (ptr1),z
    bne L3                  ; Branch if filename is not empty
    ldz tmp4
    ldx #0
:   lda noFilename,x
    beq L4
    jsr petsciiToScreenCode
    nop
    sta (ptr2),z
    inx
    inz
    inc tmp4
    bne :-
L3: ldz tmp3
    nop
    lda (ptr1),z
    beq L4
    jsr petsciiToScreenCode
    nop
    sta (ptr2),z
    inc tmp3
    inc tmp4
    bne L3
L4: ldz #EDITFILE::dirty
    nop
    lda (ptr1),z
    beq L5
    ldz tmp3
    ldx #0
:   lda modifiedStr,x
    beq L5
    jsr petsciiToScreenCode
    sta (ptr2),z
    inz
    inx
    bne :-
L5: inc tmp1
    lda tmp1
    cmp #FILES_PER_PAGE+1
    beq DN
    ldz #EDITFILE::nextFile
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    lda tmp2
    clc
    adc #4
    sta tmp2
    jmp L1
DN: rts
.endproc

; This routine locates the pointer to the EDITFILE structure
; for the first file for a page. It leaves it ptr1.
.proc getFirstFileForPage
    lda #1
    sta tmp1                    ; tmp1 is file number
    neg
    neg
    lda firstFile
    neg
    neg
    sta ptr1
:   lda tmp1
    cmp fileRangeLow
    beq :+
    ldz #EDITFILE::nextFile
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    inc tmp1
    bne :-
:   rts
.endproc

; This routine counts the number of open files and
; stores it in fileCount.
.proc countActiveFiles
    ldq firstFile           ; Copy firstFile to ptr1
    stq ptr1
    lda #0
    sta tmp1                ; tmp1 is count of files
L1: ldq ptr1
    jsr isQZero
    beq L2
    inc tmp1
    ldz #EDITFILE::nextFile
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    bra L1
L2: lda tmp1
    sta fileCount
    rts
.endproc

; This routine renders the file screen outline, including the borders
; and instructional text.
.proc renderFileScreenOutline
    clc
    jsr renderCursor        ; Clear the cursor
    jsr clearScreen

    ; Draw the first row
    ldq rowPtrs
    stq ptr1
    lda #CH_UL_CORNER
    ldz #4
    nop
    sta (ptr1),z
    inz
    ldx #69
    jsr drawHorizLine
    lda #CH_UR_CORNER
    nop
    sta (ptr1),z
    inz

    ; Draw the header row
    ldq rowPtrs+4
    stq ptr1
    lda #CH_VERT_LINE
    ldz #4
    nop
    sta (ptr1),z
    ldz #74
    nop
    sta (ptr1),z
    ldz #24
    ldx #0
:   lda fileScreenHeader,x
    beq :+
    jsr petsciiToScreenCode
    nop
    sta (ptr1),z
    inz
    inx
    bne :-

    ; Draw the header divider row
:   ldq rowPtrs+8
    stq ptr1
    lda #CH_LEFT_TEE
    ldz #4
    nop
    sta (ptr1),z
    inz
    ldx #69
    jsr drawHorizLine
    lda #CH_RIGHT_TEE
    nop
    sta (ptr1),z

    ; Draw rows with side borders
    lda screenrows
    sec
    sbc #13
    sta tmp1                ; Use tmp1 as a counter
    lda #12
    sta tmp2                ; Use tmp2 as an offset into rowPtrs
:   ldx tmp2
    lda rowPtrs,x
    sta ptr1
    lda rowPtrs+1,x
    sta ptr1+1
    lda rowPtrs+2,x
    sta ptr1+2
    lda rowPtrs+3,x
    sta ptr1+3
    lda #CH_VERT_LINE
    ldz #4
    nop
    sta (ptr1),z
    ldz #74
    nop
    sta (ptr1),z
    inc tmp2
    inc tmp2
    inc tmp2
    inc tmp2
    dec tmp1
    bne :-

    ; Draw another divider row
    lda screenrows
    sec
    sbc #10
    tay
    jsr calcScreenPtr
    ldq ptr4
    stq ptr1
    lda #CH_LEFT_TEE
    ldz #4
    nop
    sta (ptr1),z
    inz
    ldx #69
    jsr drawHorizLine
    lda #CH_RIGHT_TEE
    nop
    sta (ptr1),z

    ; Draw a blank line
    lda screenrows
    sec
    sbc #9
    tay
    jsr calcScreenPtr
    ldq ptr4
    stq ptr1
    lda #CH_VERT_LINE
    ldz #4
    nop
    sta (ptr1),z
    ldz #74
    nop
    sta (ptr1),z

    ; Draw the bottom border
    lda screenrows
    sec
    sbc #8
    tay
    jsr calcScreenPtr
    ldq ptr4
    stq ptr1
    lda #CH_LL_CORNER
    ldz #4
    nop
    sta (ptr1),z
    inz
    ldx #69
    jsr drawHorizLine
    lda #CH_LR_CORNER
    nop
    sta (ptr1),z

    ; Draw the footer prompts
    lda screenrows
    sec
    sbc #6
    tay
    jsr calcScreenPtr
    ldq ptr4
    stq ptr1
    ldz #3
    ldx #0
:   lda footerPrompt1,x
    beq :+
    jsr petsciiToScreenCode
    nop
    sta (ptr1),z
    inz
    inx
    bne :-
:   lda screenrows
    sec
    sbc #2
    tay
    jsr calcScreenPtr
    ldq ptr4
    stq ptr1
    ldz #3
    ldx #0
:   lda footerPrompt2,x
    beq :+
    jsr petsciiToScreenCode
    nop
    sta (ptr1),z
    inz
    inx
    bne :-
:   rts
.endproc
