.include "error.inc"
.include "asmlib.inc"
.include "parser.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "4510macros.inc"

.export parseSubroutineDeclarations

.import tokenIn, parseSubroutine, appendDecl, isInUnitInterface, parserToken
.import doResync, getToken
.import tlProcFuncStart, tlDeclarationFollow, tlStatementStart

.proc parseSubroutineDeclarations
L1: lda #<tlProcFuncStart
    ldx #>tlProcFuncStart
    jsr tokenIn
    bne L9

    jsr parseSubroutine
    stq ptr2
    jsr appendDecl

    lda isInUnitInterface
    beq L2
    lda parserToken
    cmp #tcIMPLEMENTATION
    beq L9
    
    ; Semicolon
L2: resync tlDeclarationFollow, tlProcFuncStart, tlStatementStart
    lda parserToken
    cmp #tcSemicolon
    bne :+
    jsr getToken
    bra L1
:   lda isInUnitInterface
    bne L1
    lda #<tlProcFuncStart
    ldx #>tlProcFuncStart
    jsr tokenIn
    bne L3
    lda #<tlStatementStart
    ldx #>tlStatementStart
    jsr tokenIn
    beq L1
L3: lda #errMissingSemicolon
    jsr compilerError
    bra L1

L9: jsr popQ
    stq ptr1
    jsr popQ
    ldq ptr1
    rts
.endproc
