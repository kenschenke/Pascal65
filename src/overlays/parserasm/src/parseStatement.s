.include "error.inc"
.include "asmlib.inc"
.include "tokenizer.inc"
.include "4510macros.inc"
.include "parser.inc"
.include "zeropage.inc"

.export parseStatement

.import parserToken, parseIdentifier, parseCompound, parseIF, parseFOR, parseREPEAT
.import parseWHILE, parseCASE, tlStatementFollow, tlStatementStart, doResync
.import expectWarnHandler, expectErrorHandler, currentLineNumber, parserValue
.import getToken, parserError

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
    bne :+
    jsr parseCASE
    jsr pushQ
    bra L1
:   cmp #tcEXPECTWARN
    bne :+
    jsr parseExpectCompilerDirective
    jsr getToken
    jmp parseStatement
:   cmp #tcEXPECTERROR
    bne :+
    jsr parseExpectCompilerDirective
    jsr getToken
    jmp parseStatement
:   jsr pushQZero

L1: lda parserToken
    cmp #tcEndOfFile
    bne :+
    resync tlStatementFollow, tlStatementStart

:   jmp popQ
.endproc

.proc parseExpectCompilerDirective
    pha             ; save the token on the stack (tcEXPECTWARN or tcEXPECTERROR)

    ; Get the error number token
    jsr getToken
    lda parserToken
    cmp #tcNumber                   ; if (parserToken != tcNumber)
    beq :+
    lda #errInvalidNumber
    jsr parserError
    pla
    rts

:   pla             ; restore the token from the stack
    cmp #tcEXPECTWARN
    beq Warn
    cmp #tcEXPECTERROR
    beq Error
TokenError:
    lda #errUnexpectedToken
    jsr parserError
    jsr getToken
    rts

Warn:
    ; Handle EXPECTWARN directive
    lda expectWarnHandler
    sta ptr1
    lda expectWarnHandler+1
    sta ptr1+1
    bra L1

Error:
    ; Handle EXPECTERROR directive
    lda expectErrorHandler
    sta ptr1
    lda expectErrorHandler+1
    sta ptr1+1

    ; Call the handler
L1: lda ptr1
    ora ptr1+1
    beq TokenError              ; Branch if the handler address is null
    lda parserValue
    ldx currentLineNumber
    ldy currentLineNumber+1
    jmp (ptr1)
.endproc
