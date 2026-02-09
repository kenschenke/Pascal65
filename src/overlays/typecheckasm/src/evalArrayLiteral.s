;
; evalArrayLiteral.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

exprOffset = 0

.export evalArrayLiteral

.import loadStackValue, exprTypeCheck, exprLiteral

.bss

dummyType: .res .sizeof(type)
evalPtr: .res 4

.code

; This routine is called from exprTypeCheck to evaluate an array literal expression.
; The first expression is passed in Q.
.proc evalArrayLiteral
    jsr pushQ               ; push the expression onto the runtime stack

L1: ldz #exprOffset
    jsr loadStackValue
    jsr isQZero
    bne :+
    jmp DN

:   stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_ARRAY_LITERAL
    bne L2
    
    ; Expression is an embedded array literal.
    jsr pushQ               ; expression
    jsr pushQZero           ; record symtab
    lda #<dummyType
    ldx #>dummyType
    ldy #0
    ldz #0
    jsr pushQ               ; type
    lda #0
    jsr pushA
    jsr exprTypeCheck
    bra L3

    ; Check the literal
L2: ldz #exprOffset
    jsr loadStackValue
    jsr pushQ
    ; Create a new type
    lda #TYPE_VOID
    jsr pushA               ; kind
    lda #0
    jsr pushA               ; isConst
    jsr pushQZero           ; subtype
    jsr pushQZero           ; params
    jsr typeCreate
    stq evalPtr
    jsr pushQ
    jsr exprLiteral
    ; Save the new type in the expression's evalType
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::evalType
    ldx #0
:   lda evalPtr,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-

    ; Move to the next literal
L3: ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #exprOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    jmp L1

DN: jsr popQ
    rts
.endproc
