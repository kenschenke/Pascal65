.include "inputbuf.inc"
.include "runtime.inc"

.import getline

.export clearInputBuf, isInputEndOfLine, readCharFromInput, skipSpaces
.export inputBuf, inputBufUsed, inputPos

.bss

inputBuf: .res INPUTBUFLEN
inputBufUsed: .res 1
inputPos: .res 1

.code

.proc clearInputBuf
    lda #0
    sta inputBufUsed
    sta inputPos
    rts
.endproc

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
    ldx inputPos            ; Use inputPos as index into inputBuf
    lda inputBuf,x          ; Load current character from inputBuf
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
    lda #<inputBuf
    sta ptr1
    lda #>inputBuf
    sta ptr1 + 1
L2:
    cpy #INPUTBUFLEN - 1
    beq L3          ; End of input buffer reached?
    cpy inputBufUsed
    bcs L3          ; End of input buffer reached?
    lda (ptr1),y    ; Look at the next character
    cmp #' '        ; Is it a space?
    bne L4          ; Not a space
    iny             ; Go to the next character
    bne L2
L3:
    jsr getline     ; read another input line
    ldy #0          ; Reset buffer position
    beq L1
L4:
    sty inputPos    ; Put Y back into inputPos
    rts
.endproc
