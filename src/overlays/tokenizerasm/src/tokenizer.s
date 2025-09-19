;
; tokenizer.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; This file contains the main entry point for the tokenizer as well as
; the holding place for some global variables.

.include "tokenizer.inc"
.include "asmlib.inc"
.include "4510macros.inc"
.include "zeropage.inc"

.export currentLineNumber, tokenCode, tokenString, tokenizerCode, tokenValue
.export isCompilerDirective, handleTokenize

.import lineNumberChanged, openSourceFile, closeSourceFile, getCurrentChar
.import getNextToken, getChar

; The tokenizer creates a membuf to store the tokenized code. In addtion
; to the Pascal language tokens such as tcSemicolon or tcIf, identifiers and
; literals are stored in the intermediate code like this:
;
; tzIdentifier
;    The tzIdentifier code is followed by a one-byte integer string
;    length followed by the string value (not null-terminated).
;
; tzLineNum
;    This code is followed by the two-byte line number.
;
; tzToken
;    The tzToken code is followed by the one-byte TTokenCode value.
;
; tzByte, tzWord, tzCardinal
;    The code is followed by the one, two, or four-byte integer value.
;    Integers are always stored as unsigned. This is followed by a
;    one-byte integer string length then the integer as a string.
;    The negative sign (if present) is stored as a separate token.
;
; tzReal
;    This is followed by a one-byte integer string length then the
;    float as a string.
;
; tzString
;    The tzString code is followed by a two-byte integer string
;    length followed by the string value (not null-terminated).
;    The string is stored with the quotes.

.data

currentLineNumber: .res 2
tokenCode: .res 1
tokenString: .res MAX_LINE_LENGTH
tokenizerCode: .res 1
tokenValue: .res 4
isDirective: .res 1         ; non-zero if processing a compiler directive
directiveParam: .res 1      ; non-zero if the current loop iteration
                            ; is processing a compiler directive param
memBuf: .res 4              ; membuf containing tokenized code
ch: .res 1

.code

; This routine sets the Z flag if the current token is
; a compiler directive that has a paramter. For now,
; it just falls straight into isCompilerDirective.
directiveHasParam:

; This routine sets the Z flag if the current token is
; a compiler directive.
.proc isCompilerDirective
    lda tokenCode
    cmp #tcSTACKSIZE
    rts
.endproc

; Source filename pointer in A/X
.proc handleTokenize
    jsr openSourceFile

    jsr allocMemBuf
    stq memBuf

    lda #0
    sta isDirective
    sta directiveParam
    sta tokenCode

L1: lda tokenCode
    cmp #tcEndOfFile
    beq L4
    lda isDirective
    beq L2
    lda directiveParam
    bne L2

    ; Consume characters until *) is reached.
    jsr closeOutComment

L2: jsr getNextToken
    lda lineNumberChanged
    beq L3

    ; Write a tzLineNum token code
    jsr writeNewLineNumber

L3: lda tokenCode
    cmp #tcString
    bne :+
    jsr writeString
    bra L1
:   cmp #tcIdentifier
    bne :+
    jsr writeString
    bra L1
:   cmp #tcNumber
    bne :+
    jsr writeNumber
    bra L1
:   jsr writeOtherToken
    bra L1

L4: jsr closeSourceFile

    ldq memBuf
    rts
.endproc

.proc closeOutComment
L1: jsr getCurrentChar
    cmp #CH_EOF
    beq L9
    cmp #'*'
    bne L2
    jsr getChar
    cmp #')'
    bne L2
    jsr getChar
    bra L9

L2: jsr getChar
    bra L1

L9: lda #0
    sta isDirective
    rts
.endproc

.proc writeNewLineNumber
    lda #tzLineNum
    sta ch
    lda #<ch
    ldx #>ch
    ldy #1
    jsr writeBytes

    lda #<currentLineNumber
    ldx #>currentLineNumber
    ldy #2
    jsr writeBytes

    lda #0
    sta lineNumberChanged
    rts
.endproc

; Pointer to buffer in A/X
; Number of writes to write in Y
.proc writeBytes
    sta ptr2
    stx ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    phy
    ldq memBuf
    stq ptr1
    pla
    ldx #0
    jmp writeToMemBuf
.endproc

.proc writeString
    ldx #tzIdentifier
    lda tokenCode
    cmp #tcIdentifier
    beq :+
    ldx #tzString
:   stx ch
    lda #<ch
    ldx #>ch
    ldy #1
    jsr writeBytes

    jsr writeTokenString

    lda #0
    sta directiveParam
    rts
.endproc

.proc writeTokenString
    ; Calculate the length of the string
    ldx #0
:   lda tokenString,x
    beq :+
    inx
    bne :-
:   stx ch
    lda #<ch
    ldx #>ch
    ldy #1
    jsr writeBytes

    lda #<tokenString
    ldx #>tokenString
    ldy ch
    jmp writeBytes
.endproc

.proc writeNumber
    lda #<tokenizerCode
    ldx #>tokenizerCode
    ldy #1
    jsr writeBytes

    lda tokenizerCode
    cmp #tzReal
    beq L2
    cmp #tzByte
    bne :+
    ldy #1
    bra L1
:   cmp #tzWord
    bne :+
    ldy #2
    bra L1
:   ldy #4
L1: lda #<tokenValue
    ldx #>tokenValue
    jsr writeBytes
L2: jsr writeTokenString

    lda #0
    sta directiveParam
    rts
.endproc

.proc writeOtherToken
    lda #tzToken
    sta ch
    lda #<ch
    ldx #>ch
    ldy #1
    jsr writeBytes

    lda #<tokenCode
    ldx #>tokenCode
    ldy #1
    jsr writeBytes

    jsr isCompilerDirective
    bne L2
    lda #1
    sta isDirective
    sta directiveParam
    jsr directiveHasParam
    beq L1
    lda #0
    sta directiveParam
L1: lda #0
    sta tokenCode
L2: rts
.endproc
