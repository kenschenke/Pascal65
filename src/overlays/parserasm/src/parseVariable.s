.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "4510macros.inc"

.export parseVariable

.import parseSubscripts, parseField, parserToken, getToken, parserValue

.proc parseVariable
    stq ptr1
    jsr pushQ               ; name pointer

    lda #EXPR_NAME
    jsr pushA               ; expr kind
    jsr pushQZero           ; left
    jsr pushQZero           ; right
    ldq ptr1
    jsr pushQ               ; name
    jsr pushQZero           ; value
    jsr exprCreate
    jsr pushQ

    ; [ or . : Loop to parse any subscripts or fields

L1: lda parserToken
    cmp #tcLBracket
    bne LPeriod
    ldz #0
    neg
    neg
    nop
    lda (stackPointer),z
    jsr parseSubscripts
    stq ptr1
    ldx #0
    ldz #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    bra L1

LPeriod:
    cmp #tcPeriod
    bne LUpArrow
    ldz #0
    neg
    neg
    nop
    lda (stackPointer),z
    jsr parseField
    stq ptr1
    ldx #0
    ldz #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    bra L1

LUpArrow:
    cmp #tcUpArrow
    bne LDone
    ldz #0
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    lda #EXPR_POINTER
    jsr pushA               ; kind
    ldq ptr1
    jsr pushQ               ; left
    jsr pushQZero           ; right
    jsr pushQZero           ; name
    jsr pushQZero           ; value
    jsr exprCreate
    stq ptr1
    ldx #0
    ldz #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    jsr getToken
    jmp L1

LDone:
    ; This routine returns an expression node.
    ; It can be one of:
    ;
    ; EXPR_NAME - just the variable itself
    ;
    ; EXPR_SUBSCRIPT - an array reference
    ;
    ; EXPR_FIELD - a record field reference
    ;
    ; It figures this out by looking at the token after the
    ; variable. If it's a left bracket, the variable is an array
    ; and the subscripts must be parsed. If it's a period, the
    ; variable is a record and the field(s) are parsed.
    ;
    ; NOTE: The routine should maintain an empty list of subscripts
    ; that gets appended to as parsing continues within the routine.
    ; When a left bracket is detected, call parseSubscripts.
    ; It runs until it sees a right bracket and will parse additional
    ; subscripts, separated by commas. If more left brackets are found
    ; it should append those to the current subscript chain so:
    ; arr[1,2,3] is equivalent to arr[1][2][3] or arr[1,2][3].

    jsr popQ
    stq ptr1
    jsr popQ
    ldq ptr1

    rts
.endproc
