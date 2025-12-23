.include "ast.inc"
.include "asmlib.inc"
.include "error.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "4510macros.inc"

.export parseREPEAT

.import getToken, condGetToken, parseStatementList, currentLineNumber
.import parseExpression

.proc parseREPEAT
    ; REPEAT
    jsr getToken

    ; <stmt-list>
    lda #tcUNTIL
    jsr parseStatementList
    jsr pushQ

    ; UNTIL
    lda #tcUNTIL
    ldx #errMissingUNTIL
    jsr condGetToken

    ; <stmt>
    lda #0
    jsr parseExpression
    stq ptr2
    jsr popQ
    stq ptr1
    lda #STMT_REPEAT
    jsr pushA               ; kind
    ldq ptr2
    jsr pushQ               ; expression
    ldq ptr1
    jsr pushQ               ; stmt(s)
    lda currentLineNumber
    ldx currentLineNumber+1
    jsr pushAX
    jmp stmtCreate
.endproc
