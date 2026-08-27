;
; skipwhitespace.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; skipWhiteSpace routine

.include "tokenizer.inc"
.include "zeropage.inc"
.include "error.inc"
.include "asmlib.inc"

.export skipWhiteSpace

.import getLine, getChar, getCurrentChar, getCharCode, putBackChar
.import getWordToken, tokenCode, currentLineNumber

.bss

ch: .res 1

.code

; This routine consumes the input buffer and discards all single and multi-line
; comments and all whitespace. It stops when it encounters a non-whitespace
; character outside of a comment.
.proc skipWhiteSpace
    jsr getCurrentChar
    sta ch
L1: lda ch
    cmp #'/'
    bne L3
    ; Look at the next character. If it's another slash then this is a
    ; single-line comment.
    jsr getChar
    sta ch
    cmp #'/'
    bne L2
    jsr getLine
    jsr getCurrentChar
    sta ch
    bra L1
L2: jmp putBackChar

L3: cmp #'('
    bne L5
    jsr getChar
    sta ch
    cmp #'*'
    bne L4
    jsr handleMultiLineComment
    jsr getCurrentChar
    sta ch
    bra L1

L4: jmp putBackChar

L5: jsr getCharCode
    cmp #ccWhiteSpace
    beq L6
    rts

L6: jsr getChar
    sta ch
    bra L1
.endproc

.proc handleMultiLineComment
L1: lda ch
    cmp #CH_EOF                 ; Reach end of file?
    bne L2                      ; Branch if not
    lda #errUnexpectedEndOfFile
    ldx currentLineNumber
    ldy currentLineNumber+1
    jmp compilerError

L2: jsr getChar                 ; Get the next character
    sta ch
    cmp #'$'                    ; Is it a dollar sign?
    bne L3                      ; Branch if not
    ; Found a dollar sign
    jsr getChar
    ; Check for a compiler directive
    jsr getWordToken
    ; If a compiler directive was found, skip processing
    lda tokenCode
    cmp #tcSTACKSIZE
    bne L1
    rts

L3: cmp #'*'
    bne L1
    jsr getChar
    sta ch
    cmp #')'
    bne L1
    jmp getChar
.endproc
