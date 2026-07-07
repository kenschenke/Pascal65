.include "asmlib.inc"
.include "tokenizer.inc"
.include "zeropage.inc"
.include "4510macros.inc"
.include "ast.inc"

.export parseIdentifier

.import parserString, getToken, parserToken, parseSubroutineCall, currentLineNumber
.import parseAssignment, parseSubroutineCall, saveParserString, lastParserString

.data

writeStr: .byte "write"
lnStr: .asciiz "ln"

.code

.proc parseIdentifier
    jsr saveParserString
    lda #<lastParserString
    ldx #>lastParserString
    ldy #0
    ldz #0
    jsr pushQ
    jsr getToken
    jsr popQ
    stq ptr1
    lda parserToken
    cmp #tcLParen
    beq L1
    cmp #tcSemicolon
    bne L2
    ; procedure/function call
L1: lda #STMT_EXPR
    jsr pushA
    ldq ptr1
    jsr pushQ
    jsr isWriteWriteln
    jsr pushA
    jsr parseSubroutineCall
    jsr pushQ
    bra L3

L2: lda #STMT_EXPR
    jsr pushA
    ldq ptr1
    jsr parseAssignment
    jsr pushQ

L3: jsr pushQZero
    lda currentLineNumber
    ldx currentLineNumber+1
    jsr pushAX
    jsr stmtCreate
    rts
.endproc

; This routine compares parserString with "write" and "writeln"
; If it equals either one, 1 is returned in A.
.proc isWriteWriteln
    ; First, compare parserString to "write"
    ldx #0
:   lda parserString,x
    cmp writeStr,x
    bne L3
    inx
    cpx #5
    bne :-

    ; See if parserString is null-terminated with "write"
    lda parserString,x
    bne L1
    lda #1
    rts

L1: ldy #0
L2: cmp lnStr,y
    bne L3
    iny
    inx
    lda parserString,x
    cpy #3
    bne L2
    lda #1
    rts

L3: lda #0
    rts
.endproc
