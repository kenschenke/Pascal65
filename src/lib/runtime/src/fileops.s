;
; fileops.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; The files package: the file I/O routines that only work on files. The
; runtime core doesn't call them, except through the jump table, so this is
; linked only into programs that declare a file variable. The rest of file
; I/O, which console I/O needs, is in fileio.s.

.include "runtime.inc"
.include "cbm_kernal.inc"
.include "c64.inc"
.include "error.inc"
.include "types.inc"
.include "asm.inc"
.include "rtpkg.inc"

; These must match fileio.s
maxFiles = 9
fileMaskOpen = 1
maxFilename = 16

.export fileOpen, fileClose, readBytes, writeBytes, fileErase, fileAssign
.export fileRename, fileFree

.import popeax, heapFree, popToIntOp1And2, clearInputBuf
.import setIOResult, setEOF, getFileRW, currentFhIn, currentFhOut
.import fileFlags, fileBuffer, errChannelOpen, ioResult, fileOpsBss

files = fileFlags
buffer = fileBuffer

; The package's variables are reserved in the core (see pkgbss.s)
ren1 = fileOpsBss
ren2 = fileOpsBss + 2

; The package header (see rtpkg.inc)
pkgHeader "FILES", RT_PKG_FILES
pkgEntry RT_FILEOPEN, fileOpen
pkgEntry RT_FILECLOSE, fileClose
pkgEntry RT_FILEERASE, fileErase
pkgEntry RT_FILEASSIGN, fileAssign
pkgEntry RT_FILERENAME, fileRename
pkgEntry RT_FILEFREE, fileFree
pkgEntry RT_WRITEBYTES, writeBytes
pkgEntry RT_READBYTES, readBytes
pkgEnd

.segment "FILES"

; Return an unused file handle in A (1-10)
; A is 1 if reading, 0 if writing
; If no available file handles, 0 is returned
.proc createFh
    pha                     ; Push R/W flag
    ldx #0
L1: cpx #maxFiles
    beq ER
    lda files,x
    beq DN
    inx
    jmp L1
ER: lda #4
    jsr setIOResult
    pla
    lda #0
    rts
DN: pla                     ; Pop R/W flag
    asl                     ; Move R/W flag to bit 2
    asl
    ora #1                  ; Mark the file as open
    sta files,x
    inx
    txa
    rts
.endproc

.proc openErrChannel
    lda #15                 ; File number 15
    tay                     ; Copy to command channel
    ldx DEVNUM              ; Device number
    bne :+
    ldx #8                  ; Default to device 8
:   jsr SETLFS
    lda #0                  ; No filename
    tax
    tay
    jsr SETNAM
    jmp OPEN
.endproc

; This helper routine copies a filename from ptr3 to buffer.
; X is the current offset in buffer
; On exit, X is updated to the new offset
.proc copyFilename
    ldy #0
    lda (ptr3),y
    sta tmp2
    iny
:   lda tmp2
    beq :+
    lda (ptr3),y
    sta buffer,x
    dec tmp2
    iny
    inx
    bne :-
:   rts
.endproc

; This routine frees a file handle's resources. If it was assigned a
; filename, the string is freed. If the file is still open, it is closed.
; This file handle is popped off the top of the stack.
.proc fileFree
    jsr popToIntOp1And2                 ; Pop the file handle into intOp1/intOp2
    lda intOp1                          ; Load the pointer to the filename string
    ora intOp1 + 1
    beq :+                              ; Branch if filename not assigned
    lda intOp1                          ; Free the string object for the filename
    ldx intOp1 + 1
    jsr heapFree
:   lda intOp2                          ; Load the file number
    beq :+                              ; Branch if not open
    lda #<intOp1                        ; Load the pointer to intOp1/intOp2
    ldx #>intOp1
    jsr fileClose                       ; Close the file
:   rts
.endproc

; This routine checks if the file exists. It does this by
; attempting to rename the file to itself. If the file does
; not exist, error 62 is returned by DOS.
; A/X contains pointer to filename string object
; tmp2 is destroyed
.proc doesFileExist
    sta ptr1
    sta ptr2
    stx ptr1 + 1
    stx ptr2 + 1
    jmp renameFile
.endproc

; This routine reads the drive's error channel. If it detects an
; error it sets IOResult and returns a 1 in A. 0 is returned in A
; if no error is detected.
.proc driveErrorCheck
    jsr CLRCHN
    ldx #15
    jsr CHKIN               ; Set file number 15 to input
    jsr CHRIN               ; Get the first number
    asl
    asl
    asl
    asl                     ; Shift it left four times
    sta tmp1                ; Store high nibble
    jsr CHRIN               ; Get the second number
    and #15                 ; Mask out the high nibble
    ora tmp1                ; Combine with the first byte
    sta tmp1
    ; Continue reading until CR
:   jsr CHRIN
    cmp #13
    bne :-
    lda tmp1
    cmp #$26                ; Disk is write protected
    bne :+
    lda #150
    jsr setIOResult
    jmp ER
:   cmp #$74                ; Drive not ready
    bne :+
    lda #152
    jsr setIOResult
    jmp ER
:   cmp #$62                ; File not found
    bne :+
    lda #2
    jsr setIOResult
    jmp ER
:   jsr CLRCHN
    lda #0
    rts
ER: jsr CLRCHN
    lda #1
    rts
.endproc

; This routine renames a file by issuing the the rename DOS command.
; ptr1 is the pointer to the original filename string object.
; ptr2 is the pointer to the new filename string object.
; tmp2 is destroyed
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
    lda ptr2
    sta ptr3
    lda ptr2 + 1
    sta ptr3 + 1
    jsr copyFilename
    lda #'='
    sta buffer,x
    inx
    lda ptr1
    sta ptr3
    lda ptr1 + 1
    sta ptr3 + 1
    jsr copyFilename
    jsr writeDosCommand
    jmp driveErrorCheck
.endproc

; This routine checks the filename for length and invalid characters.
; On entry, ptr2 points to the string object
; On exit, A is non-zero if the filename is invalid.
; If invalid, IOResult is set.
.proc checkFilename
    ldy #0
    lda (ptr2),y                ; Load filename length
    cmp #maxFilename-1          ; Compare it to DOS maximum length
    bcs ER                      ; Branch if > max length
    cmp #0                      ; Is the filename empty?
    beq ER                      ; Branch if so
    tax                         ; Copy length to X
:   iny                         ; Move to next index
    lda (ptr2),y                ; Load next character in filename
    cmp #'*'                    ; Compare it to '*'
    beq ER                      ; Branch if equal
    cmp #'?'                    ; Compare it to '?'
    beq ER                      ; Branch if equal
    dex                         ; Decrement length
    bne :-                      ; Loop if length is still > 0
    txa                         ; Copy X (which is zero) to A
    rts
ER: lda #7
    jsr rtSetIOResult
    lda #1
    rts
.endproc

; This routine handles the Pascal Assign procedure.
; A/X point to the file handle
; ptr2 points to the string object to assign
.proc fileAssign
    sta buffer                  ; Store pointer to file handle
    stx buffer + 1              ; in buffer[0] and buffer[1]
    jsr checkFilename           ; Check for invalid filename
    cmp #0
    bne DN                      ; Branch if invalid
    lda ptr2
    ldx ptr2 + 1
    ldy #TYPE_STRING_OBJ
    jsr rtConvertString         ; Make a copy
    sta buffer + 2              ; Store converted filename in buffer[2] and buffer[3]
    stx buffer + 3
    ; If file handle already has assigned filename, free it first
    lda buffer
    sta ptr1
    lda buffer + 1
    sta ptr1 + 1
    ldy #0
    lda (ptr1),y
    iny
    ora (ptr1),y
    beq :+
    lda (ptr1),y
    tax
    dey
    lda (ptr1),y
    jsr heapFree
:   lda buffer
    sta ptr1                    ; Store file handle pointer in ptr1
    lda buffer + 1
    sta ptr1 + 1
    ldy #0                      ; Copy converted filename pointer to file handle
    lda buffer + 2
    sta (ptr1),y                ; Store pointer to copy
    iny
    lda buffer + 3
    sta (ptr1),y
DN: rts
.endproc

; This routine erases a file from the disk.
; It assumes IOResult has already been reset to 0.
; A/X contains pointer to the File or Text handle.
.proc fileErase
    sta ptr1                    ; Store pointer to file handle in ptr1
    stx ptr1 + 1
    ; Check if filename has been assigned
    ldy #0
    lda (ptr1),y
    iny
    ora (ptr1),y
    bne :+
    lda #102
    jmp setIOResult
    ; Check if the file is currently open
:   ldy #2
    lda (ptr1),y
    beq :+
    lda #106
    jmp setIOResult
    ; Copy the filename pointer to ptr3
:   ldy #0
    lda (ptr1),y
    sta ptr3
    iny
    lda (ptr1),y
    sta ptr3 + 1
    ; Open the error channel if not already open
    lda errChannelOpen
    bne :+
    jsr openErrChannel
    ; Start the scratch command
:   ldx #0
    lda #'s'
    sta buffer,x
    inx
    lda #':'
    sta buffer,x
    inx
    ; Copy the rest of the filename
    jsr copyFilename
    ; Send the scratch command
    jsr writeDosCommand
    jmp driveErrorCheck
.endproc

; This routine is called by Pascal Reset and Rewrite procedures.
; It assumes IOResult has already been reset to 0.
; A/X contains pointer to the File or Text handle
; Y contains a 1 if opening for read, 0 if write
.proc fileOpen
    sta ptr4
    stx ptr4 + 1
    sty tmp3                    ; Store R/W flag in tmp3
    ; Check if filename has been assigned
    ldy #0
    lda (ptr4),y
    iny
    ora (ptr4),y
    bne :+
    lda #102
    jmp setIOResult
    ; Check if the file is already open
:   ldy #2
    lda (ptr4),y
    beq :+
    lda #106
    jmp setIOResult
    ; Open the error channel if not already open
:   lda errChannelOpen
    bne :+
    jsr openErrChannel
    ; Check if the file exists
:   ldy #1
    lda (ptr4),y
    tax
    dey
    lda (ptr4),y
    jsr doesFileExist
    cmp tmp3                    ; Compare result with R/W flag
                                ; 0 in A = file exists, 0 in tmp3 = writing
                                ; 1 in A = does not exist, 1 in tmp3 = reading
    bne NE                      ; Branch if no error
    lda tmp3                    ; Load R/W flag into A
    bne DN                      ; Branch if reading (return with error)
    ; File is being opened for writing and the file already exists.
    ; Delete the file and clear IOResult.
    lda ptr4
    ldx ptr4 + 1
    jsr fileErase               ; Erase the file
    lda ioResult                ; Load IOResult
    bne DN                      ; Branch if non-zero (error)
NE: lda #0
    jsr setIOResult             ; Clear IOResult
    lda tmp3                    ; Load R/W flag into A
    jsr createFh                ; Allocate a file number
    cmp #0
    beq DN                      ; Exit if file number is 0
    ldy #2
    sta (ptr4),y                ; Store new file number in file handle
    ; Call SETLFS
    ldx DEVNUM                  ; Last used device number
    tay                         ; Copy file number is Y
    iny                         ; Increment by 1
    jsr SETLFS
    ; Copy filename to buffer and add ",s,r/w"
    ldy #0
    lda (ptr4),y
    sta ptr2
    iny
    lda (ptr4),y
    sta ptr2 + 1
    ldy #0
    lda (ptr2),y                ; Load filename length
    sta tmp2                    ; Store it in tmp2
    ldx #0                      ; Set buffer index
:   iny                         ; Move to next character in filename
    cpx tmp2                    ; Is index = filename length?
    beq :+                      ; Branch ahead if so
    lda (ptr2),y                ; Load next character of filename
    sta buffer,x                ; Store it in the buffer
    inx                         ; Incremement buffer index
    bne :-                      ; Loop for the next character
:   lda #','                    ; Add a comma to the buffer
    sta buffer,x                ; Store it in the buffer
    inx                         ; Next buffer index
    lda #'s'                    ; Add an 's'
    sta buffer,x                ; Store it
    inx                         ; Next buffer index
    lda #','                    ; Add another comma
    sta buffer,x                ; Store it too
    inx                         ; Next buffer index
    lda #'r'                    ; Load 'r'
    ldy tmp3                    ; Load R/W flag
    cpy #0                      ; Is it 0 (write)?
    bne :+                      ; Branch if 1 (read)
    lda #'w'                    ; Load a 'w' (for write)
:   sta buffer,x                ; Store 'r' or 'w' in the buffer
    inx                         ; Next buffer index
    ; Call SETNAM
    txa                         ; Copy filename length to A
    ldx #<buffer
    ldy #>buffer
    jsr SETNAM
    ; Call OPEN
    jsr OPEN
    ; Start reading the file with an empty input buffer
    lda tmp3                    ; Load R/W flag
    beq :+                      ; Branch if writing
    jsr clearInputBuf
:   jsr driveErrorCheck
DN: rts
.endproc

; This handles the Pascal Close procedure
; This assumes the IOResult has already been cleared
; A/X contains pointer to file handle
.proc fileClose
    sta ptr1                    ; Store file handle pointer in ptr1
    stx ptr1 + 1
    ldy #2
    lda (ptr1),y                ; Load file number
    beq ER                      ; Branch if it's zero
    tax                         ; Copy it to X
    dex                         ; Decrement by 1
    txa
    pha                         ; Store 0-based file number on stack
    lda files,x                 ; Load file status
    and #fileMaskOpen           ; Mask fileOpen bit
    beq NO                      ; Branch if file not open
    inx                         ; Increment X (back to 1-based file number)
    txa                         ; Copy it A
    jsr CLOSE                   ; Close the file
    pla                         ; Pop 0-based file number off stack
    tax                         ; Copy it to X
    lda #0
    sta files,x                 ; Clear file flags
    ldy #2
    sta (ptr1),y                ; Clear file number in file handle
    ; Unread input from the closed file must not be read from the
    ; next file.
    jsr clearInputBuf
    ; If no other files are open, close the error channel too
    ldx #0
:   lda files,x
    bne :+
    inx
    cpx #maxFiles
    bne :-
    lda #15
    jsr CLOSE
    lda #0
    sta errChannelOpen
:   rts
NO: pla                         ; Pop the file number pushed above
ER: lda #103
    jmp setIOResult
.endproc

; ptr1 - pointer to file handle
; ptr2 - pointer to new filename string object
.proc fileRename
    lda #0
    jsr setIOResult
    lda ptr1
    sta ren1
    sta ptr3
    lda ptr1 + 1
    sta ren1 + 1
    sta ptr3 + 1
    lda ptr2
    sta ren2
    lda ptr2 + 1
    sta ren2 + 1
    ; Make sure file is assigned
    ldy #0
    lda (ptr1),y
    iny
    ora (ptr1),y
    beq NA
    ; Make sure file is not currently open
    ldy #2
    lda (ptr1),y
    bne FO
    ; Check new filename
    jsr checkFilename
    cmp #0
    bne BF
    ; Rename the file
    ldy #0
    lda (ptr3),y
    sta ptr1
    iny
    lda (ptr3),y
    sta ptr1 + 1
    jsr renameFile
    cmp #0
    beq :+
    rts
:   lda ren2
    sta ptr2
    lda ren2 + 1
    sta ptr2 + 1
    lda ren1
    ldx ren1 + 1
    jmp fileAssign
NA: lda #102
    jmp setIOResult
BF: lda #7
    jmp setIOResult
FO: lda #106
    jmp setIOResult
.endproc

; The runtime stack contains a pointer to the data and, above that,
; the 16-bit length.
.proc readBytes
    jsr popeax                  ; Pop the length
    sta tmp1                    ; Store it in tmp and tmp2
    stx tmp2
    jsr popeax                  ; Pop the data pointer
    sta ptr1                    ; Store it in ptr1
    stx ptr1 + 1
    lda currentFhIn
    beq ZF                      ; Branch if file number is zero
    jsr getFileRW
    cmp #0
    bne :+
    lda currentFhIn
    jsr setEOF
ZF: lda #104
    jmp setIOResult
:   ldy #0
LP: lda tmp1                    ; Check if the length is zero
    ora tmp2
    beq DN                      ; Branch if so
    jsr CHRIN                   ; Read a byte from the file
    sta (ptr1),y                ; Store it in the buffer
    lda STATUS                  ; Check for EOF
    beq :+                      ; Branch if not EOF
    lda currentFhIn             ; Load current input file number
    jmp setEOF                  ; Set EOF flag and stop reading
:   inc ptr1                    ; Increment the pointer
    bne :+                      ; Branch if low byte of pointer didn't overlow
    inc ptr1 + 1                ; Increment the high byte
:   dec tmp1                    ; Decrement the length
    bne LP
    lda tmp2
    beq DN
    dec tmp2
    jmp LP
DN: rts
.endproc

; This routine has nothing with do writeByte. It is used to write
; bytes to a file.
; The runtime stack contains a pointer to the data and, above that,
; the 16-bit length.
.proc writeBytes
    jsr popeax
    sta tmp1
    stx tmp2
    jsr popeax
    sta ptr1
    stx ptr1 + 1
    lda currentFhOut
    beq ER
    jsr getFileRW
    cmp #0
    beq :+
    lda #105
    jmp setIOResult
:   ldy #0
LP: lda tmp1
    ora tmp2
    beq DN
    lda (ptr1),y
    jsr CHROUT
    iny
    bne :+
    inc ptr1 + 1
:   dec tmp1
    bne LP
    lda tmp2
    beq DN
    dec tmp2
    jmp LP
ER: lda #103
    jsr setIOResult
DN: rts
.endproc

; This routine writes the DOS command in the buffer to
; the command channel (#15).
; X contains the number of characters to write
.proc writeDosCommand
    stx tmp2
    ; Make sure the command channel is open
    lda errChannelOpen
    bne :+
    jsr openErrChannel
    ; Set file 15 to output
:   ldx #15
    jsr CHKOUT              ; Set output file to 15
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

