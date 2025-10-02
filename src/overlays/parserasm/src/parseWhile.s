.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "astlib.inc"
.include "parser.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "4510macros.inc"

.export parseWHILE

.import getToken, parseExpression, doResync, condGetToken, parseStatement
.import currentLineNumber
.import tlDO, tlStatementStart

.proc parseWHILE
    ; WHILE
    jsr getToken

    ; <expr>
    lda #0
    jsr parseExpression
    jsr pushQ

    ; DO
    resync tlDO, tlStatementStart
    lda #tcDO
    ldx #errMissingDO
    jsr condGetToken

    ; <stmt>
    jsr parseStatement
    stq ptr2
    jsr popQ
    stq ptr1
    lda #STMT_WHILE
    jsr pushA               ; kind
    ldq ptr1
    jsr pushQ               ; expr
    ldq ptr2
    jsr pushQ               ; body
    lda currentLineNumber
    ldx currentLineNumber+1
    jsr pushAX
    jmp stmtCreate
.endproc
