;
; getnexttoken.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; getNextToken routine

.include "tokenizer.inc"
.include "cbm_kernal.inc"
.include "error.inc"

.export getNextToken

.import skipWhiteSpace, getChar, getCurrentChar, getCharCode, tokenCode
.import getWordToken, getNumberToken, getStringToken, getSpecialToken
.import getHexToken, getCharValueToken, getBinaryToken, isCompilerDirective

.proc compilerError
    rts
.endproc

; This routine scans the input buffer and gets the next token.
; The token is stored in tokenCode.
.proc getNextToken
    jsr skipWhiteSpace

    ; If the skipWhiteSpace routine encountered a compiler directive inside
    ; a comment then it leaves the tokenCode set to that directive. If so,
    ; return so the directive can be tokenized and the comment closed out.
    jsr isCompilerDirective
    bne :+              ; Branch if the current token is not a compiler directive
    rts

:   jsr getCurrentChar
    jsr getCharCode
    cmp #ccLetter
    bne :+
    jmp getWordToken
:   cmp #ccDigit
    bne :+
    clc
    jmp getNumberToken
:   cmp #ccQuote
    bne :+
    jmp getStringToken
:   cmp #ccSpecial
    bne :+
    jmp getSpecialToken
:   cmp #ccDollar
    bne :+
    jmp getHexToken
:   cmp #ccHash
    bne :+
    jmp getCharValueToken
:   cmp #ccPercent
    bne :+
    jmp getBinaryToken
:   cmp #ccEndOfFile
    bne :+
    lda #tcEndOfFile
    sta tokenCode
    rts
:   lda #errUnexpectedToken
    jsr compilerError
    jmp getChar
.endproc
