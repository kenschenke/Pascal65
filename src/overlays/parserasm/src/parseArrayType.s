.include "ast.inc"
.include "asmlib.inc"
.include "astlib.inc"
.include "error.inc"
.include "parser.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "4510macros.inc"

outerArrayOffset = 4
arrayTypeOffset = 0

.export parseArrayType

.import getToken, condGetToken, parseTypeSpec, tokenIn, parserToken
.import tlIndexFollow, tlIndexStart, tlStatementStart, tlDeclarationStart
.import tlIndexListFollow, doResync

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

    ; left bracket
    jsr getToken
    lda #tcLBracket
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
    lda parserToken
    ldx #<tlIndexStart
    ldy #>tlIndexStart
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
    lda #tcOF
    ldx #errMissingOF
    jsr condGetToken

    ; Final element type
    lda #0
    jsr parseTypeSpec
    stq ptr2
    jsr setSubtype

    ; Return the outer array type
    jsr popQ
    stq ptr1
    jsr popQ
    ldq ptr1
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
