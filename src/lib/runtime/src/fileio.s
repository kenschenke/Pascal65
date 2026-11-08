;
; fileio.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; File I/O: the part of it that is in the runtime core. Console I/O goes
; through these routines, so they're linked into every program. The routines
; that only work on files (open, close, assign, erase, rename, and block
; reads and writes) are in fileops.s, the files package, which is linked only
; when a program declares a file variable.

.include "runtime.inc"
.include "cbm_kernal.inc"
.include "c64.inc"
.include "error.inc"
.include "types.inc"

; These must match fileops.s
maxFiles = 9
fileMaskOpen = 1
fileMaskEOF = 2
fileMaskRW = 4

.export initFileIo, setFh, currentFhIn, currentFhOut, writeByte, writeData
.export isEOF, setEOF, setIOResult, getIOResult, isFileOpen, getFileRW

; For the files package (fileops.s)
.export fileFlags, fileBuffer, errChannelOpen, ioResult

.import runtimeError, addToStringBuffer

.bss

currentFhIn: .res 1             ; file number, fhStdio, or fhString
currentFhOut: .res 1            ; file number, fhStdio, or fhString
ioResult: .res 1                ; last file I/O error status
errChannelOpen: .res 1          ; non-zero if error channel is open
fileBuffer:
buffer: .res 34

; Array of file flags
;    Bit 0 - 1 if file number is open
;    Bit 1 - 1 if file has reach EOF
;    Bit 2 - 1 if file is open for reading, 1 if writing
fileFlags:
files: .res maxFiles

.code

.proc initFileIo
    lda #fhStdio
    sta currentFhIn
    sta currentFhOut
    ldx #maxFiles - 1
    lda #0
:   sta files,x
    dex
    bpl :-
    sta errChannelOpen
    rts
.endproc

; This routine determines whether or not a file is open
; A contains 1-based file number
; Returns 1 in A if file is open
.proc isFileOpen
    tax
    dex
    lda files,x
    and #fileMaskOpen
    rts
.endproc

; This routine determins whether or not a file is open for reading or writing
; A contains 1-based file number
; Returns 1 in A if file is open for reading, 0 if open for writing
.proc getFileRW
    tax
    dex
    lda files,x
    and #fileMaskRW
    lsr
    lsr
    rts
.endproc

; Sets current input or output file handle
; A - new file handle
; X - 0:output, 1:input
; 0 is returned if no error, 1 on error
.proc setFh
    sta tmp1                    ; Store new FH in tmp1
    stx tmp2                    ; Store I/O in tmp2
    cmp #0                      ; Is the file handle being cleared?
    bne :+                      ; Branch if not
    jsr CLRCHN                  ; Clear I/O channels
    jmp storeFh                 ; Store file handle
:   cmp #fhStdio                ; Is file now stdio?
    bne :+                      ; Branch if not
    jsr CLRCHN                  ; Clear all file channels
    jmp storeFh                 ; Store new file handle
:   cmp #fhString               ; Is file now string I/O?
    bne :+                      ; Branch if not
    jmp storeFh                 ; Store new file handle
:   ldx tmp1                    ; Load new file handle into X
    dex                         ; Decrement since files is 0-based
    lda files,x                 ; Check if file handle is allocated
    bne :+                      ; Branch if not
    lda #rteInvalidFileHandle   ; Invalid filehandle
    jmp runtimeError            ; Bail out
:   jsr storeFh
    ldx tmp1
    lda tmp2                    ; Look at I/O flag
    bne IN                      ; Branch if input
    jsr CHKOUT                  ; Set file to output
    lda #0
    rts
IN: jsr CHKIN
    lda #0
    rts
.endproc

; This helper routine stores the new filehandle
; in currentFhIn or currentFhOut
; tmp1 already contains new file handle
; tmp2 already contains I/O flag
.proc storeFh
    lda tmp2
    bne IN
    lda tmp1
    sta currentFhOut
    rts
IN: lda tmp1
    sta currentFhIn
    rts
.endproc

; This routine sets the EOF flag for a file
; A contains 1-bases file number on entry
.proc setEOF
    tax                     ; Copy file number to X
    beq :+
    cpx #fhString           ; A string (ReadStr) has no file flags
    beq :+
    dex                     ; Decrement by 1 (file number is 1-based)
    lda files,x             ; Load flags for file
    ora #fileMaskEOF        ; Mask non-EOF flags
    sta files,x             ; Store flags for file
:   rts
.endproc

; This routine determines if a file has reached EOF based on
; the EOF flag in the files array
; A contains 1-based file number on entry
; A contains 1 if EOF on exit
.proc isEOF
    tax                     ; Copy file number to X
    beq NO                  ; Branch if file number is zero
    cpx #fhString           ; ReadStr's string has only one line,
    beq NO                  ; so it is always at EOF after it
    dex                     ; Decrement by 1 (file number is 1-based)
    lda files,x             ; Load flags for file
    and #fileMaskEOF        ; Mask non-EOF flags
    lsr                     ; Shift EOF flag into bit 0
    rts
NO: lda #1
    rts
.endproc

; This routine sets the IOResult
.proc setIOResult
    sta ioResult
    rts
.endproc

; This routine returns and clears the IOResult
.proc getIOResult
    lda ioResult
    ldx #0
    stx ioResult
    rts
.endproc

; This routine writes one byte to the current output.
; The contents of A/X/Y are preserved.
;
; Byte in A
.proc writeByte
    sta buffer
    pha
    txa
    pha
    tya
    pha
    ldx currentFhOut
    cpx #fhString
    beq :+
    pla
    tay
    pla
    tax
    pla
    jmp CHROUT
:   lda #<buffer
    ldx #>buffer
    ldy #1
    jsr addToStringBuffer
    pla
    tay
    pla
    tax
    pla
    rts
.endproc

; This routine writes data to the current output.
;
; Pointer to data to A/X
; Length in Y
.proc writeData
    sta ptr1                        ; Store source data pointer in ptr1
    stx ptr1 + 1
    sty tmp1                        ; Store data length in tmp1
    lda currentFhOut
    cmp #fhString                   ; Is current output a string?
    bne :+                          ; Branch if not
    lda ptr1
    ldx ptr1 + 1
    ldy tmp1
    jmp addToStringBuffer
:   lda currentFhOut                ; Load current output file number
    bmi L1                          ; Branch if fhStdio
    beq NO                          ; Branch if zero
    jsr isFileOpen                  ; Check if file is open
    cmp #0
    bne :+                          ; Branch if it is
NO: lda #103
    jmp setIOResult
    ; Make sure the file is open for writing
:   lda currentFhOut                ; Load current output file number
    jsr getFileRW                   ; Is it open for writing?
    cmp #0
    beq L1                          ; Branch if so
    lda #105
    jmp setIOResult
L1: ldx tmp1
    ldy #0
:   lda (ptr1),y
    jsr CHROUT
    iny
    dex
    bne :-
    rts
.endproc

