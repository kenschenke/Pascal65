;
; parseAssignment.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Parse an assignment statement

.include "asmlib.inc"
.include "parser.inc"
.include "tokenizer.inc"
.include "ast.inc"
.include "zeropage.inc"
.include "4510macros.inc"
.include "error.inc"

targetOffset = 0

.export parseAssignment

.import parseVariable, doResync, condGetToken, tlColonEqual, tlExpressionStart
.import parseExpression

.proc parseAssignment
    jsr parseVariable
    jsr pushQ               ; target

    ; :=
    resync tlColonEqual, tlExpressionStart
    lda #tcColonEqual
    ldx #errMissingColonEqual
    jsr condGetToken

    jsr popQ
    stq ptr1

    lda #EXPR_ASSIGN
    jsr pushA               ; kind

    ldq ptr1
    jsr pushQ               ; left

    ; <expr>
    lda #0
    jsr parseExpression
    jsr pushQ               ; right
    jsr pushQZero           ; name
    jsr pushQZero           ; value
    jmp exprCreate
.endproc
