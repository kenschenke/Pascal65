;
; editorstate.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Load and save editor state

.include "editor.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"
.include "c64.inc"
.include "asmlib.inc"

.export editorHasState, editorSaveState, editorRestoreState

.import doesFileExist, helpTitle, firstFile, isQZero
.import initFile, fnBuf, openFile, scratchFile, openHelpFile
.import updateStatusBarFilename

.data

stateFilename:
stateFilenameRead: .byte "zzstate"
stateFilename2: .byte ",s,r"
stateFilenameRead2:
stateFilenameWrite: .byte "zzstate,s,w"
stateFilenameWrite2:
tempPRG: .asciiz "zzprg"

.bss

stateMemBuf: .res 4
numFiles: .res 1
chBuf: .res 2
theCurrentFile: .res 4

.code

; This code loads and saves editor state. It is used when running a compiled
; program from within the IDE. The editor state is saved before running
; the program. The program reruns the editor that then reloads the saved state.
; The state is aved to a file on the disk.
;
; State File Contents:
;
;    1. Number of open files.
;    2. For each open file:
;          a. Filename
;                i. If the file is "help.txt", it is loaded as the
;                   help file, read-only.
;          b. Cursor X position
;          c. Cursor Y position
;          d. Row offset
;          e. Column offset
;
; State File Layout:
;    <1 byte> Number of open files
;
;    For each file:
;       <1 byte>  1 if this was the file current file, 0 otherwise
;       <1 byte>  Length of filename
;       <n bytes> Filename
;       <1 byte>  Cursor X position
;       <2 bytes> Cursor Y position
;       <1 byte>  Column offset
;       <2 bytes> Row offset

.struct EDITSTATE
    isCurrentFile .byte
    filenameLength .byte
    filename .dword
    cursorX .byte
    cursorY .word
    colOffset .byte
    rowOffset .word
.endstruct

; This routine counts the number of open files and returns
; that number in A. The Z flag is set if the number is 0.
.proc countOpenFiles
    lda #0
    sta tmp1
    ldq firstFile
    stq ptr1
L1: jsr isQZero
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
    rts
.endproc

.proc deleteStateFile
    lda #<fnBuf
    sta ptr1
    lda #>fnBuf
    sta ptr1+1
    lda #0
    sta ptr1+2
    sta ptr1+3

    ldx #0
    ldy #0
:   lda stateFilename,x
    sta (ptr1),y
    iny
    inx
    cpx #stateFilename2-stateFilename
    bne :-
    lda #0
    sta (ptr1),y
    jsr scratchFile
    rts
.endproc

.proc deleteTempPRG
    lda #<tempPRG
    sta ptr1
    lda #>tempPRG
    sta ptr1+1
    lda #0
    sta ptr1+2
    sta ptr1+3
    jmp scratchFile
.endproc

; This routine checks if an editor state file exists.
; The Z flag is set if it does not exist, cleared otherwise.
.proc editorHasState
    ; Copy the state filename to fnBuf so it can be null-terminated.
    lda #<stateFilename
    sta ptr1
    lda #>stateFilename
    sta ptr1+1
    lda #<fnBuf
    sta ptr2
    lda #>fnBuf
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3

    ldx #stateFilename2-stateFilename-1
    ldy #0
:   lda (ptr1),y
    sta (ptr2),y
    iny
    dex
    bpl :-
    lda #0
    sta (ptr2),y

    ldq ptr2
    jmp doesFileExist
.endproc

.proc editorRestoreState
    ldx DEVNUM
    lda #1
    tay
    iny
    jsr SETLFS
    lda #stateFilenameRead2-stateFilenameRead
    ldx #<stateFilenameRead
    ldy #>stateFilenameRead
    jsr SETNAM
    jsr OPEN
    ldx #1
    jsr CHKIN

    ; Read the number of files in the saved state
    jsr CHRIN
    sta numFiles
    beq L2

    jsr allocMemBuf
    stq stateMemBuf

    ; Read from the state file until EOF, storing everything in the membuf.
L1: jsr CHRIN
    sta chBuf
    ; Write the character to the membuf
    jsr setUpMemBufPtrs
    lda #1
    ldx #0
    jsr writeToMemBuf
    lda STATUS
    cmp #$40
    bne L1
L2: lda #1
    jsr CLOSE
    jsr CLRCHN

    lda numFiles
    beq :+
    jsr openFilesFromState

:   jsr deleteStateFile
    jmp deleteTempPRG
.endproc

.proc editorSaveState
    jsr countOpenFiles
    sta tmp1
    bne :+
    rts

:   ldx DEVNUM
    lda #1
    tay
    iny
    jsr SETLFS
    lda #stateFilenameWrite2-stateFilenameWrite
    ldx #<stateFilenameWrite
    ldy #>stateFilenameWrite
    jsr SETNAM
    jsr OPEN
    ldx #1
    jsr CHKOUT

    ; Write number of files
    lda tmp1
    jsr CHROUT

    jsr writeOpenFiles

    lda #1
    jsr CLOSE
    jsr CLRCHN
    rts
.endproc

; This routine determines whether or not the filename in fnBuf
; is the help file. If so, the zero flag is set.
.proc isHelpFile
    ldx #0
L1: lda helpTitle,x
    beq L2
    cmp fnBuf,x
    bne L3
    inx
    bne L1
L2: lda fnBuf,x
L3: rts
.endproc

; This routine opens a file from the state membuf.
.proc openFileFromState
    ; Read the filename length
    jsr setUpMemBufPtrs
    lda #1
    ldx #0
    jsr readFromMemBuf
    ; chBuf contains filename length
    ; Read the filename
    lda #<fnBuf
    sta ptr2
    lda #>fnBuf
    sta ptr2+1
    lda chBuf
    ldx #0
    jsr readFromMemBuf
    ldx chBuf
    lda #0
    sta fnBuf,x

    jsr isHelpFile
    bne L1
    jsr openHelpFile
    bra L2
L1: jsr openFile

    ; Read cursorX
L2: jsr setUpMemBufPtrs
    lda #1
    ldx #0
    jsr readFromMemBuf
    lda chBuf
    ldz #EDITFILE::cx
    nop
    sta (currentFile),z

    ; Read cursorY
    jsr setUpMemBufPtrs
    lda #2
    ldx #0
    jsr readFromMemBuf
    lda chBuf
    ldz #EDITFILE::cy
    nop
    sta (currentFile),z
    lda chBuf+1
    inz
    nop
    sta (currentFile),z

    ; Read colOff
    jsr setUpMemBufPtrs
    lda #1
    ldx #0
    jsr readFromMemBuf
    lda chBuf
    ldz #EDITFILE::colOff
    nop
    sta (currentFile),z

    ; Read rowOff
    jsr setUpMemBufPtrs
    lda #2
    ldx #0
    jsr readFromMemBuf
    lda chBuf
    ldz #EDITFILE::rowOff
    nop
    sta (currentFile),z
    lda chBuf+1
    inz
    nop
    sta (currentFile),z

    rts
.endproc

; This routine opens all the files from the state
; in the membuf.
.proc openFilesFromState
    ldq stateMemBuf
    stq ptr1
    lda #0
    tax
    jsr setMemBufPos

    ; Read isCurrentFile from membuf
L1: jsr setUpMemBufPtrs
    lda #1
    ldx #0
    jsr readFromMemBuf
    lda chBuf
    pha

    jsr openFileFromState

    pla
    beq :+
    ldq currentFile
    stq theCurrentFile

:   dec numFiles
    bne L1

    ldq stateMemBuf
    jsr freeMemBuf
    ldq theCurrentFile
    stq currentFile
    jsr updateStatusBarFilename
    rts
.endproc

; This routine sets up ptr1 and ptr2 for a membuf calls
.proc setUpMemBufPtrs
    ldq stateMemBuf
    stq ptr1
    lda #<chBuf
    sta ptr2
    lda #>chBuf
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    rts
.endproc

; This routine writes the editor state to the current output file.
.proc writeOpenFiles
    ldq firstFile
    stq ptr1

L1: ldq ptr1
    jsr isQZero
    bne :+
    rts

    ; Is this the current file?
:   ldx #0
:   lda ptr1,x
    cmp currentFile,x
    bne L2
    inx
    cpx #4
    beq L3
    bra :-

L2: lda #0
    bra L4
L3: lda #1
L4: jsr CHROUT

    ; Count length of filename
    ldz #EDITFILE::filename
    ldx #0
:   nop
    lda (ptr1),z
    beq :+
    inz
    inx
    bne :-
:   txa
    jsr CHROUT

    ; Write the filename
    ldz #EDITFILE::filename
:   nop
    lda (ptr1),z
    beq :+
    jsr CHROUT
    inz
    bra :-

    ; Write the cursor X position
:   ldz #EDITFILE::cx
    nop
    lda (ptr1),z
    jsr CHROUT

    ; Write the cursor Y position
    ldz #EDITFILE::cy
    nop
    lda (ptr1),z
    jsr CHROUT
    inz
    nop
    lda (ptr1),z
    jsr CHROUT

    ; Write the column offset
    ldz #EDITFILE::colOff
    nop
    lda (ptr1),z
    jsr CHROUT

    ; Write the row offset
    ldz #EDITFILE::rowOff
    nop
    lda (ptr1),z
    jsr CHROUT
    inz
    nop
    lda (ptr1),z
    jsr CHROUT

    ; Go to the next file
    ldz #EDITFILE::nextFile
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    bra L1
.endproc

