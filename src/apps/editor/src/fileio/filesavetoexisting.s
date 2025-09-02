;
; filesavetoexisting.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; saveToExisting routine

.include "editor.inc"
.include "zeropage.inc"
.include "4510macros.inc"
.include "cbm_kernal.inc"
.include "c64.inc"

.export saveToExisting

.import scratchFile, renameFile, isQZero, fileWrite, makeFilename

.data

tmpFn: .asciiz "tmp.txt"

.code

; This routine saves the lines from the current file.
.proc saveToExisting
    ; Call SETLFS
    ldx DEVNUM
    lda #1
    tay
    iny
    jsr SETLFS
    ; Call SETNAM
    lda #<tmpFn
    ldx #>tmpFn
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
    ; Erase the original file
    lda #EDITFILE::filename
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq currentFile
    clc
    adcq intOp32
    stq ptr1
    jsr scratchFile
    ; Rename the temporary file to the original filename
    ldq ptr1
    stq ptr2
    lda #<tmpFn
    sta ptr1
    lda #>tmpFn
    sta ptr1+1
    lda #0
    sta ptr1+2
    sta ptr1+3
    jsr renameFile
    rts
.endproc
