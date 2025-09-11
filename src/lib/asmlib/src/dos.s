;
; dos.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; CBM DOS routines

.include "cbm_kernal.inc"
.include "c64.inc"
.include "4510macros.inc"
.include "zeropage.inc"

.export scratchFile, renameFile, IOResult, makeFilename, doesFileExist

.bss

buffer: .res 34
IOResult: .res 1

.code

; This helper routine copies a filename from ptr3 to the buffer.
; The filename is expected to be null-terminated.
; X is the current offset in the buffer.
; On exit, X is updated to the new offset.
.proc copyFilename
    ldz #0
:   nop
    lda (ptr3),z
    beq :+
    sta buffer,x
    inz
    inx
    bne :-
:   rts
.endproc

; This routine checks if the file exists. It does this
; by attempting to rename the file to itself. If the file
; does not exist, error 2 is returned by DOS.
; Q contains the pointer to the null-terminated filename.
; A is non-zero if the file exists
.proc doesFileExist
    stq ptr1
    stq ptr2
    jsr renameFile
    lda IOResult
    sec
    sbc #2
    rts
.endproc

; This routine read's the drive's error channel. It it detects an
; error it sets IOResult and returns a 1 in A. 0 is returned in A
; if no error is detected.
.proc driveErrorCheck
    lda #0
    sta IOResult
    jsr CLRCHN
    ldx #15
    jsr CHKIN           ; Set file number 15 to input
    jsr CHRIN           ; Get the first number
    asl
    asl
    asl
    asl                 ; Shift it left four times
    sta tmp1            ; Store high nibble
    jsr CHRIN           ; Get the second number
    and #15             ; Mask out the high nibble
    ora tmp1            ; Combine the first byte
    sta tmp1
    ; Continue reading until CR
:   jsr CHRIN
    cmp #13
    bne :-
    lda tmp1            ; Read the error number back in
    cmp #$26            ; Disk is write protected
    bne :+
    lda #150
    sta IOResult
    jmp ER
:   cmp #$74            ; Drive not ready
    bne :+
    lda #152
    sta IOResult
    jmp ER
:   cmp #$62            ; File not found
    bne :+
    lda #2
    sta IOResult
    jmp ER
:   jsr CLRCHN
    lda #15
    jsr CLOSE
    lda #0
    rts
ER: jsr CLRCHN
    lda #15
    jsr CLOSE
    lda #1
    rts
.endproc

; This routine makes a CBM filename by appending ",s,r" or ",s,w"
; and returning a pointer to a buffer in bank 0 with the new filename.
; On input, Q contains the input filename and the carry flag is set
; if reading, cleared if writing.
; On exit, the A register contains the length of the filename with suffix,
; X contains the low byte of the buffer and Y contains the high byte.
.proc makeFilename
    stq ptr4
    ldx #0
    ldz #0
:   nop
    lda (ptr4),z
    beq :+
    sta buffer,x
    inz
    inx
    bne :-
:   lda #','
    sta buffer,x
    inx
    lda #'s'
    sta buffer,x
    inx
    lda #','
    sta buffer,x
    inx
    bcs :+
    lda #'w'
    sta buffer,x
    bra DN
:   lda #'r'
    sta buffer,x
DN: inx
    txa
    ldx #<buffer
    ldy #>buffer
    rts
.endproc

.proc openErrChannel
    lda #15             ; File number 15
    tay                 ; Copy to command channel
    ldx DEVNUM          ; Device number
    bne :+
    ldx #8              ; Default to device 8
:   jsr SETLFS
    lda #0
    tax
    tay
    jsr SETNAM
    jmp OPEN
.endproc

; This routine renames a file by issuing the rename DOS command.
; ptr1 is the pointer to the original filename (null-terminated).
; ptr2 is the pointer to the new filename (null-terminated).
.proc renameFile
    ; Put the rename command in the buffer
    ldx #0
    lda #'r'
    sta buffer,x
    inx
    lda #'0'
    sta buffer,x
    inx
    lda #':'
    sta buffer,x
    inx
    phx
    ldq ptr2
    stq ptr3
    plx
    jsr copyFilename
    lda #'='
    sta buffer,x
    inx
    phx
    ldq ptr1
    stq ptr3
    plx
    jsr copyFilename
    jsr writeDosCommand
    jmp driveErrorCheck
.endproc

; This routine erases a file by issuing the scratch command.
; The null-terminated filename is in ptr1
.proc scratchFile
    ; Copy ptr1 to ptr3
    ldq ptr1
    stq ptr3
    ; Put the scratch command in the buffer
    ldx #0
    lda #'s'
    sta buffer,x
    inx
    lda #':'
    sta buffer,x
    inx
    jsr copyFilename
    jsr writeDosCommand
    jmp driveErrorCheck
.endproc

; This routine writes the DOS command in the buffer
; to the command channel (#15).
; X contains the number of characters to write.
.proc writeDosCommand
    stx tmp2
    jsr openErrChannel
    ; Set file 15 to output
    ldx #15
    jsr CHKOUT          ; Set output file to 15
    ; Send the command
    ldx #0
:   lda tmp2
    beq :+
    lda buffer,x
    jsr CHROUT
    dec tmp2
    inx
    bne :-
:   rts
.endproc
