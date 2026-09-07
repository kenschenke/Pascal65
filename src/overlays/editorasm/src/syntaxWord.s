;
; syntaxWord.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; syntaxWord routine

.include "editor.inc"
.include "zeropage.inc"
.include "tokenizer.inc"

MAX_RESERVED_LENGTH = 14        ; Maximum length of any reserved word

.export syntaxWord

.import syntaxIndex, syntaxCount, syntaxCharCode

.data

rw2: .byte "do"
     .byte "if"
     .byte "in"
     .byte "of"
     .byte "or"
     .byte "to"
     .byte $0

rw3: .byte "and"
     .byte "div"
     .byte "end"
     .byte "for"
     .byte "mod"
     .byte "nil"
     .byte "not"
     .byte "set"
     .byte "var"
     .byte "xor"
     .byte $0

rw4: .byte "byte"
     .byte "case"
     .byte "char"
     .byte "else"
     .byte "file"
     .byte "goto"
     .byte "real"
     .byte "text"
     .byte "then"
     .byte "true"
     .byte "type"
     .byte "unit"
     .byte "uses"
     .byte "with"
     .byte "word"
     .byte $0

rw5: .byte "array"
     .byte "begin"
     .byte "const"
     .byte "false"
     .byte "label"
     .byte "until"
     .byte "while"
     .byte $0

rw6: .byte "downto"
     .byte "packed"
     .byte "record"
     .byte "repeat"
     .byte "string"
     .byte $0

rw7: .byte "boolean"
     .byte "integer"
     .byte "longint"
     .byte "program"
     .byte $0

rw8: .byte "cardinal"
     .byte "function"
     .byte "shortint"
     .byte $0

rw9: .byte "interface"
     .byte "procedure"
     .byte "stacksize"
     .byte $0

rw10: .byte $0

rw11: .byte $0

rw12: .byte $0

rw13: .byte $0

rw14: .byte "implementation", $0

rwTable: .byte $0, $0
         .byte $0, $0
         .byte .LOBYTE(rw2), .HIBYTE(rw2)
         .byte .LOBYTE(rw3), .HIBYTE(rw3)
         .byte .LOBYTE(rw4), .HIBYTE(rw4)
         .byte .LOBYTE(rw5), .HIBYTE(rw5)
         .byte .LOBYTE(rw6), .HIBYTE(rw6)
         .byte .LOBYTE(rw7), .HIBYTE(rw7)
         .byte .LOBYTE(rw8), .HIBYTE(rw8)
         .byte .LOBYTE(rw9), .HIBYTE(rw9)
         .byte .LOBYTE(rw10), .HIBYTE(rw10)
         .byte .LOBYTE(rw11), .HIBYTE(rw11)
         .byte .LOBYTE(rw12), .HIBYTE(rw12)
         .byte .LOBYTE(rw13), .HIBYTE(rw13)
         .byte .LOBYTE(rw14), .HIBYTE(rw14)

.bss

wordBuffer: .res MAX_RESERVED_LENGTH
wordLength: .res 1
wordIndex: .res 1
highlightCode: .res 1

.code

; This routine is called when the syntax highlighter encounters a letter. It looks at
; characters in the buffer until it finds a character other than a letter or digit.
; It checks the word against the list of reserved words. If it is a reserved word,
; the highlight codes are set to SYNTAXHL_KEYWORD. Otherwise, the codes are SYNTAXHL_NONE.
.proc syntaxWord
    lda #$ff
    sta highlightCode
    jsr copySyntaxWord
    lda highlightCode
    cmp #$ff                    ; Is highlightCode != #$ff?
    bne :+                      ; Branch if it's not
    jsr syntaxWordToLower
    jsr getHighlightCode

    ; Set the highlight code for the characters just checked.
:   ldz syntaxIndex
    lda highlightCode
    ldx #0
L1: nop
    sta (ptr2),z
    inz
    inx
    cpx wordLength
    bne L1

    stz syntaxIndex
    rts
.endproc

; This routine copies characters from the buffer until it encounters a
; non-alphanumeric character or the word exceeds MAX_RESERVED_LENGTH.
.proc copySyntaxWord
    ldz syntaxIndex
    ldx #0
L1: nop
    lda (ptr1),z
    jsr syntaxCharCode
    cmp #shLetter
    beq L2
    cmp #shDigit
    beq L2

    ; Non-alphanumeric character encountered.
    stx wordLength
    rts

L2: cpx syntaxCount
    bne :+
    ; Reached the end of the line
    lda #SYNTAXHL_NONE
    sta highlightCode
    stx wordLength
    rts
:   cpx #MAX_RESERVED_LENGTH
    bne L3
    ; Too long to be a reserved word
    lda #SYNTAXHL_NONE
    sta highlightCode
    stx wordLength
    rts

L3: nop
    lda (ptr1),z
    sta wordBuffer,x

    inx
    inz
    bra L1
.endproc

; This routine converts the letters in wordBuffer to lower case.
.proc syntaxWordToLower
    ldx #0
L1: lda wordBuffer,x
    jsr syntaxCharCode
    cmp #shLetter
    bne L2

    ; Convert to lower case
    lda wordBuffer,x
    and #$7f
    sta wordBuffer,x

L2: inx
    cpx wordLength
    bne L1

    rts
.endproc

; This routine checks wordBuffer against the list of reserved words.
; The highlight code is returned in A, SYNTAXHL_NONE or SYNTAXHL_KEYWORD.
.proc getHighlightCode
    lda wordLength
    asl a
    tax
    lda rwTable,x
    sta ptr3
    lda rwTable+1,x
    sta ptr3+1

    ; Is ptr3 null?
    lda ptr3
    ora ptr3+1
    bne L1
    lda #SYNTAXHL_NONE
    sta highlightCode
    rts

    ; Loop through the words in the table in ptr3 and
    ; check each one.
L1: ldy #0
    lda (ptr3),y
    bne L2
    ; End of the table
    lda #SYNTAXHL_NONE
    sta highlightCode
    rts

L2: jsr isReservedWord
    bne L3
    lda #SYNTAXHL_KEYWORD
    sta highlightCode
    rts

    ; Not a match. Go to the next word.
L3: lda ptr3
    clc
    adc wordLength
    sta ptr3
    lda ptr3+1
    adc #0
    sta ptr3+1
    bra L1
.endproc

; This routine checks the reserved word in wordBuffer
; against the string in ptr3.
;
; On exit, the Z flag is set if the word matches.
.proc isReservedWord
    ldy #0
L1: lda (ptr3),y
    cmp wordBuffer,y
    bne L2

    iny
    cpy wordLength
    bne L1

L2: rts
.endproc
