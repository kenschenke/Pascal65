;
; fileread.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Routines to read a file into the editor

.include "editor.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "c64.inc"
.include "4510macros.inc"
.include "asmlib.inc"

.export readTitleFile, openFile, openFileRO, openHelpFile, fnBuf
.export helpTitle

.import titleScreen, anyDirtyRows, editorAllocLine
.import updateStatusBarFilename, editorSetDefaultStatusMessage, initFile
.import addCurrentFile, makeFilename, isQZero, resetScreenSettings

.bss

lineBuf: .res MAX_LINE_LENGTH
lastLine: .res 4
thisLine: .res 4
fnBuf: .res 20          ; filename buffer in bank 0 for SETNAM

.data

titleFilename: .byte "title.txt,s,r"
titleFilename2:
helpFilename: .asciiz "help.txt"
helpTitle: .asciiz "Help File"

.code

; This routine opens a file from the null-terminated filename in fnBuf.
; The routine then calls readFile which adds the lines to currentFile.
.proc openFile
    ; Allocate a file
    jsr initFile
    ; Call SETLFS
    ldx DEVNUM
    lda #1
    tay
    iny
    jsr SETLFS
    ; Save filename pointer to ptr1
    lda #<fnBuf
    sta ptr1
    lda #>fnBuf
    sta ptr1+1
    ; Count filename length and copy filename to currentFile
    ldy #0
    ldz #EDITFILE::filename
:   lda (ptr1),y
    beq :+
    nop
    sta (currentFile),z
    iny
    inz
    bne :-
:   lda #<fnBuf
    ldx #>fnBuf
    ldy #0
    ldz #0
    sec
    jsr makeFilename
    jsr SETNAM
    jsr OPEN
    ldx #1
    jsr CHKIN
    jsr readFile
    lda #1
    jsr CLOSE
    ldx #0
    jsr CHKIN           ; Set the input device back to the keyboard
    ; Add currentFile to list of open files
    jsr addCurrentFile
    ; Mark all rows as dirty (need to be rendered)
    lda #1
    sta anyDirtyRows
    jsr editorSetDefaultStatusMessage
    jsr updateStatusBarFilename
    ; Reset screen settings. This is necessary because CHKIN
    ; and CLRCHN reset the screen RAM pointer for some reason.
    jsr resetScreenSettings
    rts
.endproc

; This routine opens a file by calling openFile
; then sets the read-only flag.
.proc openFileRO
    jsr openFile
    ldz #EDITFILE::readOnly
    lda #1
    nop
    sta (currentFile),z
    rts
.endproc

.proc openHelpFile
    lda #<helpFilename
    sta ptr1
    lda #>helpFilename
    sta ptr1+1
    ldy #0
    ldx #0
:   lda (ptr1),y
    sta fnBuf,x
    beq :+
    inx
    iny
    bne :-
:   jsr openFileRO
    ; Copy help file title
    ldz #EDITFILE::filename
    ldx #0
:   lda helpTitle,x
    nop
    sta (currentFile),z
    beq :+
    inz
    inx
    bne :-
:   jsr updateStatusBarFilename
    rts
.endproc

; This routine reads a file into the editor. The file is already open
; and set with CHKIN.
.proc readFile
    lda #0
    tax
    tay
    taz
    stq lastLine
    ; Read bytes from the file until EOL or EOF
L1: ldx #0
L2: phx
    jsr CHRIN
    plx
    ldy STATUS
    cpy #$40
    bne L3              ; Branch if not EOF
    jmp saveLine
L3: cpy #0
    beq L4
    rts
L4: cmp #13             ; Is that a CR?
    bne :+
    ; Carriage return
    jsr saveLine
    jmp L1
:   sta lineBuf,x
    inx
    jmp L2
.endproc

.proc readTitleFile
    ldx DEVNUM
    lda #1
    tay
    iny
    jsr SETLFS
    lda #titleFilename2-titleFilename
    ldx #<titleFilename
    ldy #>titleFilename
    jsr SETNAM
    jsr OPEN
    ldx #1
    jsr CHKIN
    jsr readFile
    lda #1
    jsr CLOSE
    ldx #0
    jsr CHKIN           ; Set the input device back to the keyboard
    ldq currentFile
    stq titleScreen
    rts
.endproc

.proc saveLine
    phx                         ; Save the line length on the CPU stack
    jsr editorAllocLine
    ldq ptr1
    stq thisLine                ; Save the pointer
    ldz #EDITLINE::length
    pla                         ; Pop the line length back off the CPU stack
    nop
    sta (ptr1),z                ; Save the line length
    ldz #EDITLINE::capacity
    nop
    sta (ptr1),z
    cmp #0
    beq L1                      ; Skip allocating and copying if the length is zero
    pha                         ; Push the line length onto the CPU stack
    ldx #0
    jsr heapAlloc               ; Allocate a buffer for the line data
    stq ptr2
    ldq thisLine
    stq ptr1
    ldz #EDITLINE::buffer+3
    ldx #3
:   lda ptr2,x                  ; Copy the pointer for the line data into EDITLINE
    nop
    sta (ptr1),z
    dez
    dex
    bpl :-
    ; Copy the contents of lineBuf into the new line (contents in ptr2)
    pla                         ; Pop the line length off the CPU stack
    sta tmp1                    ; and put it in tmp1
    ldx #0
    ldz #0
:   lda lineBuf,x
    nop
    sta (ptr2),z
    inz
    inx
    cpx tmp1
    bne :-
    ; Add the new line to the linked list of lines
L1: jsr addLine
    ldq thisLine                ; Copy thisLine to lastLine
    stq lastLine
    ; Increment numLines in currentFile
    ldz #EDITFILE::numLines
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
    rts
.endproc

; This routine adds the line in thisLine to lastLine.
; If lastLine is null then the line is stored in currentFile.
.proc addLine
    ldq lastLine
    jsr isQZero
    bne L1                  ; branch if lastLine is null
    ; lastLine is null -- store thisLine as first line in currentFile
    ldz #EDITFILE::firstLine+3
    ldx #3
:   lda thisLine,x
    nop
    sta (currentFile),z
    dez
    dex
    bpl :-
    rts
L1: ; lastLine is non-NULL. Save thisLine to be lastLine's next.
    ldq lastLine            ; Copy lastLine to ptr2
    stq ptr2
    ldz #EDITLINE::next+3
    ldx #3
:   lda thisLine,x
    nop
    sta (ptr2),z
    dez
    dex
    bpl :-
    rts
.endproc
