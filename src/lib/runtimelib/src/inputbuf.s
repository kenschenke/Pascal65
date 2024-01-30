.include "inputbuf.inc"
.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp clearInputBuf
jmp isInputEndOfLine
jmp readCharFromInput
jmp skipSpaces

; end of exports
.byte $00, $00, $00

; imports

getline: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

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
    ldy #0          ; Reset buffer position
    beq L1
L3:
    sty inputPos    ; Put Y back into inputPos
    rts
.endproc
