.include "asmlib.inc"
.include "tokenizer.inc"
.include "4510macros.inc"
.include "parser.inc"
.include "zeropage.inc"

.export parseStatement

.import parserToken, parseIdentifier, parseCompound, parseIF, parseFOR, parseREPEAT
.import parseWHILE, parseCASE, tlStatementFollow, tlStatementStart, doResync

stmtOffset = 0

.proc parseStatement
    lda parserToken
    cmp #tcIdentifier
    bne :+
    jsr parseIdentifier
    jsr pushQ
    bra L1
:   cmp #tcBEGIN
    bne :+
    jsr parseCompound
    jsr pushQ
    bra L1
:   cmp #tcIF
    bne :+
    jsr parseIF
    jsr pushQ
    bra L1
:   cmp #tcFOR
    bne :+
    jsr parseFOR
    jsr pushQ
    bra L1
:   cmp #tcREPEAT
    bne :+
    jsr parseREPEAT
    jsr pushQ
    bra L1
:   cmp #tcWHILE
    bne :+
    jsr parseWHILE
    jsr pushQ
    bra L1
:   cmp #tcCASE
    bne L1
    jsr parseCASE
    jsr pushQ

L1: lda parserToken
    cmp #tcEndOfFile
    bne :+
    resync tlStatementFollow, tlStatementStart

:   jmp popQ
.endproc
