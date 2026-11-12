;
; parseSubroutineDeclarations.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Parse the function and procedure declarations of a block

.include "error.inc"
.include "asmlib.inc"
.include "parser.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "4510macros.inc"

.export parseSubroutineDeclarations

.import tokenIn, parseSubroutine, appendDecl, isInUnitInterface, parserToken
.import doResync, getToken
.import tlProcFuncStart, tlDeclarationFollow, tlStatementStart, parserError
.import tlDeclarationStart

.proc parseSubroutineDeclarations
L1: lda #<tlProcFuncStart
    ldx #>tlProcFuncStart
    jsr tokenIn
    bne L9

    jsr parseSubroutine
    stq ptr2
    jsr appendDecl

    ; In a unit's interface the header's semicolon is already read. Any
    ; token but another routine ends the list, and parseBlock reports a
    ; missing Implementation.
    lda isInUnitInterface
    beq L2
    jmp L1

    ; Semicolon
L2: resync tlDeclarationFollow, tlDeclarationStart, tlStatementStart
    lda parserToken
    cmp #tcSemicolon
    bne :+
    jsr getToken
    bra L1
:   lda #errMissingSemicolon
    jsr parserError
    bra L1

L9: jsr popQ
    stq ptr1
    jsr popQ
    ldq ptr1
    rts
.endproc
