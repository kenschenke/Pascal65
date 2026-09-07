;
; syntaxHighlight.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; syntaxHighlight routine

.include "editor.inc"
.include "zeropage.inc"
.include "tokenizer.inc"

; Syntax highlighting is done by calculating the highlight value of each
; character in a line of text. The value is one of the following:
;
;    SYNTAXHL_NONE
;    SYNTAXHL_NUMBER
;    SYNTAXHL_KEYWORD
;    SYNTAXHL_STRING
;    SYNTAXHL_COMMENT
;
; These are stored in a buffer in the EDITLINE structure that corresponds
; to the characters on that line. While rendering, the screen code uses
; the highlight values to render the color for each character.

.export syntaxHighlight
.export syntaxCount, syntaxIndex, syntaxIsNextChar, syntaxIsHexDigit

.import huntForCommentClose, syntaxCharCode, syntaxWord, syntaxNumber
.import syntaxString, syntaxSinglelineComment, syntaxMultilineComment
.import syntaxHex, syntaxBinary

.bss

syntaxCount: .res 1       ; Number of characters in current buffer
syntaxIndex: .res 1       ; Index in buffers

.code

; This routine calculates the syntax highlighting for a line of text.
; Inputs:
;    ptr1 - pointer to characters for line
;    ptr2 - pointer to buffer of highlight values
;    A    - number of characters in buffer
;    Carry flag is set if a multi-line comment is continued from previous line
;
; Outputs:
;    Carry flag is set if a multi-line comment remains open
.proc syntaxHighlight
    sta syntaxCount
    lda #0
    sta syntaxIndex
    bcc L1
    jsr huntForCommentClose
    bcc L1
    rts

    ; Loop through the characters on the line
L1: lda syntaxCount
    cmp syntaxIndex
    bne :+
    lda #0
    clc
    rts
:   bcs :+
    clc
    rts
:   ldz syntaxIndex
    nop
    lda (ptr1),z
    cmp #'('
    bne :+
    ; Is the next character a '*'?
    ldx #'*'
    jsr syntaxIsNextChar
    bne :+
    jsr syntaxMultilineComment
    bcc L1
    rts
:   cmp #'/'
    bne :+
    ; Is the next character another '/'?
    ldx #'/'
    jsr syntaxIsNextChar
    bne :+
    jsr syntaxSinglelineComment
    clc
    lda #0
    rts
:   cmp #'''
    bne :+
    jsr syntaxString
    jmp L1
:   cmp #'$'
    bne :+
    jsr syntaxIsHexDigitNext
    bne :+
    jsr syntaxHex
    jmp L1
:   cmp #'%'
    bne :+
    ldx #'0'
    jsr syntaxIsNextChar
    beq BN
    ldx #'1'
    jsr syntaxIsNextChar
    beq BN
    bra :+
BN: jsr syntaxBinary
    jmp L1
:   cmp #'.'
    bne L2
    ldx #'.'
    jsr syntaxIsNextChar
    bne :+
    jsr syntaxDotDot
    jmp L1
:   jsr syntaxIsDigitNext
    bne L2
    lda #1
    jsr syntaxNumber
    jmp L1
L2: jsr syntaxCharCode
    cmp #shLetter
    bne :+
    jsr syntaxWord
    jmp L1
:   cmp #ccDigit
    bne :+
    lda #0
    jsr syntaxNumber
    jmp L1
:   lda #SYNTAXHL_NONE
    ldz syntaxIndex
    nop
    sta (ptr2),z
    inc syntaxIndex
    jmp L1
.endproc

; This routine tests if the next character is the same as the one in X.
; If so, the Z flag is set. The routine will not set the Z flag if
; the current character is the last one on the line.
;
; A is preserved if not equal
.proc syntaxIsNextChar
    ldy syntaxIndex
    iny
    cpy syntaxCount
    bcc :+
    ldy #1
    rts
:   pha
    stx tmp1
    ldz syntaxIndex
    inz
    nop
    lda (ptr1),z
    cmp tmp1
    bne :+
    pla
    lda #0
    rts
:   pla
    rts
.endproc

; This routine tests if the next character is a digit 0-9.
; If so, the Z flag is set. The routine will not set the Z flag if
; the current character is the last one on the line.
;
; A is preserved if not equal
.proc syntaxIsDigitNext
    ldy syntaxIndex
    iny
    cpy syntaxCount
    bcc :+
    ldy #1
    rts
:   pha
    ldz syntaxIndex
    inz
    nop
    lda (ptr1),z
    jsr syntaxCharCode
    cmp #ccDigit
    bne :+
    pla
    lda #0
    rts
:   pla
    rts
.endproc

; This routine tests if the next character is a digit 0-9 or letter a-f or A-F.
; If so, the Z flag is set. The routine will not set the Z flag if
; the current character is the last one on the line.
;
; A is preserved if not equal
.proc syntaxIsHexDigitNext
    ldy syntaxIndex
    iny
    cpy syntaxCount
    bcc :+
    ldy #1
    rts
:   pha
    ldz syntaxIndex
    inz
    nop
    lda (ptr1),z
    jsr syntaxIsHexDigit
    bne :+
    pla
    lda #0
    rts
:   pla
    rts
.endproc

; This routine determines if the character in A is a hex digit.
; The Z flag is set if it is.
.proc syntaxIsHexDigit
    pha
    jsr syntaxCharCode
    cmp #ccDigit
    bne :+
    pla
    lda #0
    rts
:   cmp #ccLetter
    bne :+
    ; Convert to lower case
    ldz syntaxIndex
    nop
    lda (ptr1),z
    jsr syntaxIsHexLetter
    bne :+
    pla
    lda #0
    rts
:   pla
    rts
.endproc

; This routine determines if the letter in A is A through F.
; The Z flag is set if it is.
.proc syntaxIsHexLetter
    and #$7f            ; convert to lower case
    cmp #'a'
    beq :+
    cmp #'b'
    beq :+
    cmp #'c'
    beq :+
    cmp #'d'
    beq :+
    cmp #'e'
    beq :+
    cmp #'f'
:   rts
.endproc

; This routine is called when the .. operator is found.
.proc syntaxDotDot
    ldz syntaxIndex
    lda #SYNTAXHL_NONE
    nop
    sta (ptr2),z
    inz
    inc syntaxIndex
    nop
    sta (ptr2),z
    inc syntaxIndex
    rts
.endproc
