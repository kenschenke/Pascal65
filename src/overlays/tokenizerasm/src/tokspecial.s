;
; tokspecial.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; getSpecialToken routine

.include "tokenizer.inc"
.include "asmlib.inc"
.include "error.inc"

.export getSpecialToken

.import tokenCode, getNumberToken, getChar, getCurrentChar, getCharCode
.import currentLineNumber

; This routine tokenizes any non-numeric or identifier in the source file.
; What is left is mostly operators.
.proc getSpecialToken
    jsr getCurrentChar

    cmp #'^'
    bne :+
    lda #tcUpArrow
    jmp DN

:   cmp #'*'
    bne :+
    lda #tcStar
    jmp DN

:   cmp #'('
    bne :+
    lda #tcLParen
    jmp DN

:   cmp #')'
    bne :+
    lda #tcRParen
    jmp DN

:   cmp #'-'
    bne :+
    lda #tcMinus
    jmp DN

:   cmp #'+'
    bne :+
    lda #tcPlus
    jmp DN

:   cmp #'='
    bne :+
    lda #tcEqual
    jmp DN

:   cmp #'['
    bne :+
    lda #tcLBracket
    jmp DN

:   cmp #']'
    bne :+
    lda #tcRBracket
    jmp DN

:   cmp #';'
    bne :+
    lda #tcSemicolon
    jmp DN

:   cmp #','
    bne :+
    lda #tcComma
    jmp DN

:   cmp #'/'
    bne :+
    lda #tcSlash
    jmp DN

:   cmp #'!'
    bne :+
    lda #tcBang
    jmp DN

:   cmp #'&'
    bne :+
    lda #tcAmpersand
    jmp DN

:   cmp #'@'
    bne :+
    lda #tcAt
    jmp DN

:   cmp #':'
    bne LT
    ; Could be : or :=
    jsr getChar
    cmp #'='
    beq :+
    lda #tcColon
    sta tokenCode
    rts
:   lda #tcColonEqual
    jmp DN

LT: cmp #'<'
    bne GT
    ; Could be < or <= or <> or <<
    jsr getChar
    cmp #'='
    bne :+
    lda #tcLe
    jmp DN
:   cmp #'>'
    bne :+
    lda #tcNe
    jmp DN
:   cmp #'<'
    bne :+
    lda #tcLShift
    jmp DN
:   lda #tcLt
    sta tokenCode
    rts

GT: cmp #'>'
    bne DT
    ; Could be > or >= or >>
    jsr getChar
    cmp #'='
    bne :+
    lda #tcGe
    jmp DN
:   cmp #'>'
    bne :+
    lda #tcRShift
    jmp DN
:   lda #tcGt
    sta tokenCode
    rts

DT: cmp #'.'
    bne ER
    ; Could be . or .. or .<digit>
    jsr getChar
    cmp #'.'
    bne :+
    lda #tcDotDot
    jmp DN
:   jsr getCharCode
    cmp #ccDigit
    bne :+
    sec
    jmp getNumberToken
:   lda #tcPeriod
    sta tokenCode
    rts

ER: lda #errUnexpectedToken
    ldx currentLineNumber
    ldy currentLineNumber+1
    jsr compilerError
    lda #tcError
    ; Fall through to DN

DN: sta tokenCode
    jsr getChar
    lda tokenCode
    rts
.endproc
