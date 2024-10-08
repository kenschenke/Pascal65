;
; getline.s
; Ken Schenke (kenschenke@gmail.com)
;
; Read a line of input from the console
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;

.include "inputbuf.inc"
.include "runtime.inc"

.export isInputEndOfLine, readCharFromInput, skipSpaces

.import getline, isEOF, currentFhIn

.proc isInputEndOfLine
    lda #1
    ldx inputBufUsed
    dex
    bmi L1
    cpx inputPos            ; carry set inputPos <= inputBufUsed-1 -- carry clear inputPos > inputBufUsed-1
    bcc L1
    lda #0
L1:
    ldx #0
    rts
.endproc

.proc readCharFromInput
    ldx inputBufUsed        ; Check how many unread chars in input buffer
    dex                     ; Less One
    bmi L1                  ; If negative, need to read a line
    cpx inputPos            ; Compare inputBufUsed to inputPos
    bcs L2                  ; If inputPos < inputBufUsed - 1, don't need to read
L1:
    jsr getline             ; Read a line from the input
L2:
    ldy inputPos            ; Use inputPos as index into inputBuf
    lda (inputBuf),y        ; Load current character from inputBuf
    inc inputPos            ; Move the input position forward
    ldx #0                  ; Clear X for CC65 return value
    rts
.endproc

; This routine skips ahead to the first non-space in the input
; buffer.  If it reaches the end of the input line it will read
; the next line, and so on until it finds a non-space.
.proc skipSpaces
    ldy inputPos
L1:
    cpy #INPUTBUFLEN - 1
    beq L2          ; End of input buffer reached?
    cpy inputBufUsed
    bcs L2          ; End of input buffer reached?
    lda (inputBuf),y    ; Look at the next character
    cmp #' '        ; Is it a space?
    bne L3          ; Not a space
    iny             ; Go to the next character
    bne L1
L2:
    jsr getline     ; read another input line
    lda currentFhIn ; load file handle if reading from a file
    jsr isEOF       ; check for end of file
    bne L4          ; branch if EOF
    ldy #0          ; Reset buffer position
    beq L1
L3:
    sty inputPos    ; Put Y back into inputPos
L4: rts
.endproc
