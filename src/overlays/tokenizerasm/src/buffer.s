;
; buffer.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Routines for reading a source file. A whole line of source is read at a
; time and stored in a buffer. The current character can be retrieved, the
; next character can be returned and the current character can be put back.

.include "tokenizer.inc"
.include "zeropage.inc"
.include "asmlib.inc"
.include "cbm_kernal.inc"
.include "c64.inc"
.include "buffer.inc"
.include "error.inc"

.export openSourceFile, closeSourceFile, getCurrentChar, getChar, putBackChar, getLine
.export lineNumberChanged

.import currentLineNumber

BUFFER_LENGTH = 81

.bss

buffer: .res BUFFER_LENGTH          ; Current input line buffer
pBufChar: .res 2                    ; Pointer into buffer to current character
lineNumberChanged: .res 1

.code

; This routine opens the source file. The null-terminated filename
; is passed in A/X
.proc openSourceFile
    ; Make sure the file exists first
    pha
    phx
    ldy #0
    ldz #0
    jsr doesFileExist
    cmp #0
    bne :+
    ; The file does not exist
    pla
    pla
    lda #abortSourceFileOpenFailed
    jsr abortRuntimeError
    ; Make CBM DOS filename (append ",s,r")
:   plx
    pla
    ldy #0
    ldz #0
    sec
    jsr makeFilename
    ; Call SETNAM
    jsr SETNAM
    ; Call SETLFS
    ldx DEVNUM
    lda #1
    tay
    iny
    jsr SETLFS
    jsr OPEN
    ldx #1
    jsr CHKIN
    
    ; Clear the input buffer
    lda #0
    tax
:   sta buffer,x
    inx
    cpx #MAX_LINE_LENGTH+1
    bne :-

    ; Set the current character pointer
    lda #<buffer
    sta pBufChar
    lda #>buffer
    sta pBufChar+1

    ; Clear the current line number
    lda #0
    sta currentLineNumber
    sta currentLineNumber+1

    rts
.endproc

.proc closeSourceFile
    lda #1
    jsr CLOSE
    ldx #0
    jsr CHKIN
    rts
.endproc

; This routine returns the current character from the input line buffer.
; It does not advance to the next character.
;
; The character is returned in A.
.proc getCurrentChar
    lda pBufChar
    sta ptr1
    lda pBufChar+1
    sta ptr1+1
    ldy #0
    lda (ptr1),y
    rts
.endproc

; This routine returns the current character from the line input buffer.
; The character pointer is advanced to the next character. If the input
; buffer is empty, a new line is read from the source file.
.proc getChar
    jsr getCurrentChar

    cmp #CH_EOF
    bne :+
    rts

:   cmp #0
    bne :+
    jsr getLine
    jmp getCurrentChar

:   inc pBufChar
    bne :+
    inc pBufChar+1
:   jmp getCurrentChar
.endproc

; This routine reads a line from the source file and resets the
; current character pointer to the start of the line.
.proc getLine
    ; Reset pBufChar to the beginning of the buffer
    lda #<buffer
    sta pBufChar
    lda #>buffer
    sta pBufChar+1

    ; Check for EOF
    lda STATUS
    cmp #$40
    bne :+

    ; End of file
    lda #CH_EOF
    sta buffer
    rts

:   ldy #0

L1: jsr CHRIN
    cmp #13
    bne L2
    ; CR found - end of line
    sta buffer,y
    iny
    lda #0
    sta buffer,y
    inc currentLineNumber
    bne :+
    inc currentLineNumber+1
:   lda #1
    sta lineNumberChanged
    rts

L2: sta buffer,y
    iny
    cpy #MAX_LINE_LENGTH
    bne L1
    lda #abortSourceLineTooLong
    jsr abortTranslation
    rts
.endproc

.proc putBackChar
    lda pBufChar
    sec
    sbc #1
    sta pBufChar
    lda pBufChar+1
    sbc #0
    sta pBufChar+1
    rts
.endproc

.proc abortTranslation
    rts
.endproc
