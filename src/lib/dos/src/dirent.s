;
; dirent.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; Read a directory

.include "dirent.inc"
.include "cbm_kernal.inc"

filenameLen = $10

DIRENT_SEQ = $81
DIRENT_PRG = $82
DIRENT_USR = $83
DIRENT_REL = $84

.struct DIRENT
    type        .byte
    filename    .res 16
    blocks      .word
.endstruct

.export opendir, closedir, readdir

.import createFh, freeFh, runtimeError

.data

dirname: .byte '$'

.code

; Reads a directory

; Opens the disk directory
; Device number in A
; Directory handle returned in A
.proc opendir
    pha
    jsr createFh
    sta tmp1
    ; Set the filename
    lda #1
    ldx #<dirname
    ldy #>dirname
    jsr SETNAM
    ; Set the filehandle
    pla
    tax
    lda tmp1
    ldy #0
    jsr SETLFS
    ; Open the filehandle
    jsr OPEN
    bcc :+
    lda #rteFileOpenFailed
    jmp runtimeError
    ; Activate the file
:   ldx tmp1
    jsr CHKIN
    ; Skip the first four bytes
:   ldy #4
    jsr READST
    bne ER
    jsr CHRIN
    dey
    bne :-
    lda tmp1
    rts
ER: lda #rteFileIOFailed
    jmp runtimeError
.endproc

; Closes the disk directory
; Directory handle in A
.proc closedir
    pha
    jsr CLOSE
    jsr CLRCHN
    pla
    jmp freeFh
.endproc

; Reads directory entries into caller-supplied buffer.
; Caller keeps calling readdir until A is zero
; A/X point to caller's DIRENT
; Non-zero in A if DIRENT contains valid entry
.proc readdir
.endproc
