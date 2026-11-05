;
; parseArrayType.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Parse an array type definition

.include "ast.inc"
.include "asmlib.inc"
.include "error.inc"
.include "parser.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "4510macros.inc"

arrayTypeOffset = 0
outerArrayOffset = arrayTypeOffset + 4

.export parseArrayType

.bss

dynArray: .res 4
dynIndex: .res 4

.code

.import getToken, condGetToken, parseTypeSpec, tokenIn, parserToken
.import tlIndexFollow, tlIndexStart, tlStatementStart, tlDeclarationStart
.import tlIndexListFollow, doResync, parserError

.proc parseArrayType
    jsr pushQZero           ; outerArray
    jsr pushQZero           ; arrayType

    ; Start with the outer-most array.
    ; The element type and index type are filled in later.
    lda #TYPE_ARRAY
    jsr pushA               ; kind
    lda #0
    jsr pushA               ; isConst
    jsr pushQZero           ; subtype
    jsr pushQZero           ; params
    jsr typeCreate
    stq ptr1
    ; Store it in outerArray
    ldz #outerArrayOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    ; Store it in arrayType as well
    ldz #arrayTypeOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-

    ; OF right after ARRAY is a dynamic array (Array Of T)
    jsr getToken
    lda parserToken
    cmp #tcOF
    bne :+
    jsr setDynamicIndex
    jmp L4

    ; left bracket
:   lda #tcLBracket
    ldx #errMissingLeftBracket
    jsr condGetToken

    ; Loop to parse each type spec in the index type list, separated by commas
L1: lda #1
    jsr parseTypeSpec
    stq ptr2
    ldz #arrayTypeOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #type::indextype
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-

    ; comma
    resync tlIndexFollow, tlIndexStart
    lda parserToken
    cmp #tcComma
    beq L2
    lda #<tlIndexStart
    ldx #>tlIndexStart
    jsr tokenIn
    bne L3
L2: ; For each type spec after the first, create an element type object
    lda #TYPE_ARRAY
    jsr pushA               ; kind
    lda #0
    jsr pushA               ; isConst
    jsr pushQZero           ; subtype
    jsr pushQZero           ; params
    jsr typeCreate
    stq ptr2
    ; Set a subtype for the parent array
    jsr setSubtype
    ; Update the array pointer to the new subtype
    ldz #arrayTypeOffset
    ldx #0
:   lda ptr2,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    lda #tcComma
    ldx #errMissingComma
    jsr condGetToken
    jmp L1

    ; right bracket
L3: lda #tcRBracket
    ldx #errMissingRightBracket
    jsr condGetToken

    ; OF
    resync tlIndexListFollow, tlDeclarationStart, tlStatementStart
L4: lda #tcOF
    ldx #errMissingOF
    jsr condGetToken

    ; Final element type
    lda #0
    jsr parseTypeSpec
    stq ptr2
    jsr setSubtype

    ; Only one-dimensional dynamic arrays are supported. An array
    ; can't be the element of a dynamic array, and a dynamic array
    ; can't be the element of another array.
    ldz #type::kind
    nop
    lda (ptr2),z
    cmp #TYPE_ARRAY
    bne L5
    ldz #type::flags
    nop
    lda (ptr2),z
    and #TYPE_FLAG_ISDYNAMIC
    bne :+
    ldz #arrayTypeOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #type::flags
    nop
    lda (ptr1),z
    and #TYPE_FLAG_ISDYNAMIC
    beq L5
:   lda #errMultiDimDynArray
    jsr parserError

    ; Return the outer array type
L5:
    jsr popQ
    jsr popQ
    rts
.endproc

; This routine makes the array type on the runtime stack a dynamic array.
; It sets TYPE_FLAG_ISDYNAMIC and gives the array an Integer subrange
; index type of 0..-1, an empty array. The rest of the compiler reads an
; array's limits from its index type, so it needs no special case.
.proc setDynamicIndex
    ldz #arrayTypeOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq dynArray
    stq ptr1
    ldz #type::flags
    nop
    lda (ptr1),z
    ora #TYPE_FLAG_ISDYNAMIC
    nop
    sta (ptr1),z

    ; The subrange's Integer subtype
    lda #TYPE_INTEGER
    jsr pushA               ; kind
    lda #0
    jsr pushA               ; isConst
    jsr pushQZero           ; subtype
    jsr pushQZero           ; params
    jsr typeCreate
    stq ptr1

    ; The subrange index type
    lda #TYPE_SUBRANGE
    jsr pushA               ; kind
    lda #0
    jsr pushA               ; isConst
    ldq ptr1
    jsr pushQ               ; subtype
    jsr pushQZero           ; params
    jsr typeCreate
    stq dynIndex

    ; Low limit: 0
    lda #0
    tax
    jsr makeLimitExpr
    stq ptr2
    ldq dynIndex
    stq ptr1
    ldz #type::min
    jsr storePtr2

    ; High limit: -1
    lda #$ff
    tax
    jsr makeLimitExpr
    stq ptr2
    ldq dynIndex
    stq ptr1
    ldz #type::max
    jsr storePtr2

    ; Set the array's index type
    ldq dynIndex
    stq ptr2
    ldq dynArray
    stq ptr1
    ldz #type::indextype
    jmp storePtr2
.endproc

; This routine creates a word literal expression for the
; 16-bit value in A/X. The expression is returned in Q.
.proc makeLimitExpr
    pha
    phx
    lda #EXPR_WORD_LITERAL
    jsr pushA               ; kind
    jsr pushQZero           ; left
    jsr pushQZero           ; right
    jsr pushQZero           ; name
    plx
    pla
    ldy #0
    ldz #0
    jsr pushQ               ; value
    jmp exprCreate
.endproc

; This routine stores the pointer in ptr2 in the structure
; pointed to by ptr1 at offset Z.
.proc storePtr2
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    rts
.endproc

; This routine sets the subtype of the array type on the runtime stack
; The subtype is found in ptr2.
.proc setSubtype
    ldz #arrayTypeOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #type::subtype
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    rts
.endproc
