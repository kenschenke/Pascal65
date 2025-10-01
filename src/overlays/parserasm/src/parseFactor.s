.include "asmlib.inc"
.include "astlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"
.include "tokenizer.inc"
.include "error.inc"
.include "ast.inc"

.export parseFactor, makeExpr, copyQuotedString

.import getToken, parseSubroutineCall, parserType, parserValue, parserString
.import parseVariable, parserToken, parseExpression, parseArrayLiteral
.import parserError

.data

writeStr: .asciiz "writestr"

.code

offsetVarInit = 1
offsetUnaryNeg = 0

.proc parseFactor
    jsr pushA

    lda #0
    jsr pushA               ; unaryNeg

    lda parserToken
    cmp #tcMinus
    bne LIdentifier
    lda #1
    ldz #offsetUnaryNeg
    nop
    sta (stackPointer),z
    jsr getToken
    lda parserToken

LIdentifier:
    cmp #tcIdentifier
    bne LNumber
    lda #<parserString
    ldx #>parserString
    jsr nameCreate
    jsr pushQ
    jsr getToken
    lda parserToken
    cmp #tcLParen
    bne :+
    ; Function / procedure call
    jsr isWriteStr
    jsr pushA
    jsr parseSubroutineCall
    jsr pushQ
    jmp DoNeg
:   jsr popQ
    jsr parseVariable
    stq ptr1
    jsr popA
    jsr popA
    ldq ptr1
    rts

LNumber:
    cmp #tcNumber
    bne LBoolean
    lda parserType
    cmp #tyReal
    bne :+
    jsr copyString
    lda #EXPR_REAL_LITERAL
    bra LNumberExpr
:   cmp #tyByte
    bne :+
    lda #EXPR_BYTE_LITERAL
    bra LNumberExpr
:   cmp #tyWord
    bne :+
    lda #EXPR_WORD_LITERAL
    bra LNumberExpr
:   lda #EXPR_WORD_LITERAL
LNumberExpr:
    jsr makeExpr
    jsr pushQ
    jsr getToken
    jmp DoNeg

LBoolean:
    cmp #tcTRUE
    beq LT
    cmp #tcFALSE
    beq LF
    jmp LNil
LT: lda #1
    bra :+
LF: lda #0
:   sta parserValue
    lda #0
    sta parserValue+1
    sta parserValue+2
    sta parserValue+3
    lda #EXPR_BOOLEAN_LITERAL
    jsr makeExpr
    jsr pushQ
    jsr getToken
    jmp DoNeg

LNil:
    cmp #tcNIL
    bne LString
    lda #0
    sta parserValue
    sta parserValue+1
    sta parserValue+2
    sta parserValue+3
    lda #EXPR_WORD_LITERAL
    jsr makeExpr
    jsr pushQ
    jsr getToken
    jmp DoNeg

LString:
    cmp #tcString
    bne LNot
    jsr isSingleChar
    bne :+
    lda parserString+1
    sta parserValue
    lda #0
    sta parserValue+1
    sta parserValue+2
    sta parserValue+3
    lda #EXPR_CHARACTER_LITERAL
    jsr makeExpr
    jsr pushQ
    jsr getToken
    jmp DoNeg
:   jsr copyQuotedString
    lda #EXPR_STRING_LITERAL
    jsr makeExpr
    jsr pushQ
    jsr getToken
    jmp DoNeg

LNot:
    cmp #tcNOT
    bne LAt
    jsr getToken
    lda #EXPR_NOT
    jsr makeUnaryExpr
    jsr pushQ
    jmp DoNeg

LAt:
    cmp #tcAt
    bne LLParen
    jsr getToken
    lda #EXPR_ADDRESS_OF
    jsr makeUnaryExpr
    jsr pushQ
    jmp DoNeg

LLParen:
    cmp #tcLParen
    bne LNone
    jsr getToken
    ldz #offsetVarInit
    nop
    lda (stackPointer),z            ; load isVarInit
    beq :+
    ; Array literal
    jsr parseArrayLiteral
    bra LRParen
:   lda #0
    jsr parseExpression
LRParen:
    jsr pushQ
    lda parserToken
    cmp #tcRParen
    bne :+
    jsr getToken
    jsr popQ
    stq ptr1
    jsr popA
    jsr popA
    ldq ptr1
    rts
:   jsr popQ
    lda #errMissingRightParen
    jsr parserError
    jsr pushQZero
    jmp DoNeg

LNone:
    lda #errInvalidExpression
    jsr parserError

DoNeg:
    jsr popQ
    stq ptr1
    ldz #offsetUnaryNeg
    nop
    lda (stackPointer),z
    beq :+
    ldz #expr::neg
    nop
    sta (ptr1),z
:   jsr popA
    jsr popA
    ldq ptr1
    rts
.endproc

; This routine compares parserString to "writestr" and
; returns a 1 in A if it matches, 0 otherwise.
.proc isWriteStr
    ldx #0
L1: lda parserString,x
    cmp writeStr,x
    bne L3
    lda parserString,x
    beq L2
    inx
    bne L1

L2: lda #1
    rts

L3: lda #0
    rts
.endproc

; This routine calls createExpr.
; The EXPR_* kind is in A
; 0's are passed for left, right, and name
; Whatever is in parserValue is copied in.
.proc makeExpr
    jsr pushA
    jsr pushQZero
    jsr pushQZero
    jsr pushQZero
    ldq parserValue
    jsr pushQ
    jmp exprCreate
.endproc

; This routine calls createExpr.
; The EXPR_* kind is in A
; parseFactor is called recursively for the left value.
; 0's are passed for right, and name, and value.
.proc makeUnaryExpr
    jsr pushA
    lda #0
    jsr parseFactor
    jsr pushQ
    jsr pushQZero
    jsr pushQZero
    jsr pushQZero
    jmp exprCreate
.endproc

; This routine looks at parserString and sets the Z flag
; if the string is three characters long (single quotes + char).
.proc isSingleChar
    ldx #0
:   lda parserString,x
    beq :+
    inx
    bne :-
:   cpx #3
    rts
.endproc

; This routine copies the string in parserString into a new buffer
; and stores the buffer pointer in parserValue
.proc copyQuotedString
    ; Remove the closing quote of the string
    ldx #0
:   lda parserString,x
    beq :+
    inx
    bne :-
:   dex
    lda #0
    sta parserString,x
    lda #<parserString
    sta tmp1
    lda #>parserString
    sta tmp2
    inw tmp1
    lda tmp1
    ldx tmp2
    jmp copyStringHelper
.endproc

.proc copyString
    lda #<parserString
    ldx #>parserString
    ; Fall through to copyStringHelper
.endproc

.proc copyStringHelper
    jsr nameCreate
    stq parserValue
    rts
.endproc
