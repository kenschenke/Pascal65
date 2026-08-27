;
; tokword.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; getWordToken routine

.include "tokenizer.inc"
.include "zeropage.inc"

MAX_RESERVED_LENGTH = 14        ; Maximum length of any reserved word

.export getWordToken

.import tokenCode, tokenString, getCurrentChar, getChar, getCharCode

.data

rw2: .byte "do", tcDO
     .byte "if", tcIF
     .byte "in", tcIN
     .byte "of", tcOF
     .byte "or", tcOR
     .byte "to", tcTO
     .byte $0

rw3: .byte "and", tcAND
     .byte "div", tcDIV
     .byte "end", tcEND
     .byte "for", tcFOR
     .byte "mod", tcMOD
     .byte "nil", tcNIL
     .byte "not", tcNOT
     .byte "set", tcSET
     .byte "var", tcVAR
     .byte "xor", tcXOR
     .byte $0

rw4: .byte "byte", tcBYTE
     .byte "case", tcCASE
     .byte "char", tcCHAR
     .byte "else", tcELSE
     .byte "file", tcFILE
     .byte "goto", tcGOTO
     .byte "real", tcREAL
     .byte "text", tcTEXT
     .byte "then", tcTHEN
     .byte "true", tcTRUE
     .byte "type", tcTYPE
     .byte "unit", tcUNIT
     .byte "uses", tcUSES
     .byte "with", tcWITH
     .byte "word", tcWORD
     .byte $0

rw5: .byte "array", tcARRAY
     .byte "begin", tcBEGIN
     .byte "const", tcCONST
     .byte "false", tcFALSE
     .byte "label", tcLABEL
     .byte "until", tcUNTIL
     .byte "while", tcWHILE
     .byte $0

rw6: .byte "downto", tcDOWNTO
     .byte "packed", tcPACKED
     .byte "record", tcRECORD
     .byte "repeat", tcREPEAT
     .byte "string", tcSTRING
     .byte $0

rw7: .byte "boolean", tcBOOLEAN
     .byte "integer", tcINTEGER
     .byte "longint", tcLONGINT
     .byte "program", tcPROGRAM
     .byte $0

rw8: .byte "cardinal", tcCARDINAL
     .byte "function", tcFUNCTION
     .byte "shortint", tcSHORTINT
     .byte $0

rw9: .byte "interface", tcINTERFACE
     .byte "procedure", tcPROCEDURE
     .byte "stacksize", tcSTACKSIZE
     .byte $0

rw10: .byte $0

rw11: .byte $0

rw12: .byte $0

rw13: .byte $0

rw14: .byte "implementation", tcIMPLEMENTATION, $0

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

ch: .res 1

.code

; This routine checks the identifier in tokenString against the
; list of reserved words.
.proc checkForReservedWord
    ; Assume this is an identifier and not a reserved word.
    lda #tcIdentifier
    sta tokenCode

    ; Calculate length of tokenString
    ldx #0
L1: lda tokenString,x
    beq L2
    inx
    bne L1

    ; Is the length > the max reserved word length?
    cpx #MAX_RESERVED_LENGTH
    bcs L5                  ; Branch of length > MAX_RESERVED_LENGTH

L2: stx tmp1                ; Keep word length in tmp1
    txa
    asl a
    tax
    lda rwTable,x
    sta ptr1
    lda rwTable+1,x
    sta ptr1+1

    ; Walk through the list of reserved words in the list in ptr1
L3: ldy #0
    lda (ptr1),y            ; Have we reached the end of the reserved words list?
    beq L5                  ; Branch if so
    jsr compareReservedWord
    beq L4                  ; Branch if the reserved word is a match
    ; Move to the next reserved word
    jsr advancePtr1
    inw ptr1
    bra L3

L4: ; Set the token code
    jsr advancePtr1
    ldy #0
    lda (ptr1),y
    sta tokenCode

L5: lda tokenCode
    rts
.endproc

; This is a small helper routine that advances ptr1 by the
; number of characters in the reserved word.
.proc advancePtr1
    lda ptr1
    clc
    adc tmp1
    sta ptr1
    lda ptr1+1
    adc #0
    sta ptr1+1
    rts
.endproc

; This routine compares the reserved word pointed at by ptr1
; with tokenString. If they're equal, the Z flag is set on return.
.proc compareReservedWord
    ldx #0
    ldy #0

L1: cpx tmp2
    beq L2
    lda (ptr1),y
    cmp tokenString,x
    bne L2
    inx
    iny
    bne L1

L2: lda tokenString,x
    rts
.endproc

; This routine is called when the tokenizer encounters a letter. It consumes input
; until a character other than a letter or digit is found. It checks the word against
; the list of reserved words. If it is a reserved word, the apropriate token is assigned.
; Otherwise, the word is classified as an identifier.
.proc getWordToken
    lda #<tokenString
    sta ptr2
    lda #>tokenString
    sta ptr2+1

    jsr getCurrentChar
    sta ch
    lda #0
    sta tmp2

    ; Loop 
L1: ldy tmp2
    lda ch
    sta (ptr2),y
    inc tmp2
    jsr getChar
    sta ch
    jsr getCharCode
    cmp #ccLetter
    beq L1
    cmp #ccDigit
    beq L1

    ldy tmp2
    lda #0
    sta (ptr2),y

    ; Convert the tokenString to all lowercase
    ldx #0
L2: lda tokenString,x
    beq L4
    jsr getCharCode
    cmp #ccLetter
    bne L3
    lda tokenString,x
    and #$7f
    sta tokenString,x
L3: inx
    bne L2

L4: jmp checkForReservedWord
.endproc
