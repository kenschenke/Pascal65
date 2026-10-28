;
; checkTypeCast.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

rtnTypePtrOffset = 0
exprOffset = 4

.export checkTypeCast

.import loadStackValue, typeCheckError, isTypeOrdinal

.bss

targetSymType: .res 4      ; the resolved cast-to type, as declared
targetBaseType: .res 4     ; targetSymType after resolving aliases/subranges
argExprPtr: .res 4         ; the single argument expression being cast

.code

; This routine type-checks (and rewrites) an EXPR_CALL node whose callee
; name resolves to a TYPE declaration instead of a routine, e.g.
; Integer(x). On entry the node is still shaped like a call (left: callee
; name expression, right: chain of EXPR_ARG). If the cast is legal, this
; node is rewritten in place into an EXPR_CAST node (left: the argument
; expression) and the return type is set to the target type.
;
; Parameters on the runtime stack, bottom to top:
;    Expression pointer (the call/cast node)
;    Pointer to the return type
.proc checkTypeCast
    ; Resolve the callee name to its TYPE symbol
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2                    ; ptr2 = callee EXPR_NAME
    ldz #expr::name
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr4
    jsr scopeLookup
    stq ptr2                    ; ptr2 = symbol (already known non-null)
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr2),z
    stq targetSymType

    ; Validate the argument count: must be exactly one argument
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr3                    ; ptr3 = first (and should be only) EXPR_ARG
    jsr isQZero
    bne :+                      ; no arguments
    jmp BadArity
:   ldz #expr::right
    neg
    neg
    nop
    lda (ptr3),z
    jsr isQZero
    beq :+                      ; more than one argument
    jmp BadArity
:

    ; Get the argument expression (ptr3.left)
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr3),z
    stq argExprPtr

    ; Validate the target type's category
    ldq targetSymType
    jsr getBaseType
    stq targetBaseType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    jsr isTypeCastable
    beq :+
    jmp BadType
:
    ; Validate the argument's (already evaluated) type category
    ldq argExprPtr
    stq ptr1
    ldz #expr::evalTypeKind
    nop
    lda (ptr1),z
    jsr isTypeCastable
    beq :+
    jmp BadType
:
    ; -------- Legal cast. Build the result type. --------
    ; Copy the resolved target type's kind/flags/subtype/paramFields/size
    ; into the caller-supplied return-type block, the same as a plain
    ; reference to the type would report.
    ldz #rtnTypePtrOffset
    jsr loadStackValue
    stq ptr2                    ; ptr2 = destination (return) type block
    ldq targetBaseType
    stq ptr1                    ; ptr1 = source (resolved) type

    ldz #type::kind
    nop
    lda (ptr1),z
    nop
    sta (ptr2),z

    ldz #type::flags
    nop
    lda (ptr1),z
    nop
    sta (ptr2),z

    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr3
    ldz #type::subtype
    ldx #0
:   lda ptr3,x
    nop
    sta (ptr2),z
    inz
    inx
    cpx #4
    bne :-

    ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr3
    ldz #type::paramFields
    ldx #0
:   lda ptr3,x
    nop
    sta (ptr2),z
    inz
    inx
    cpx #4
    bne :-

    ldz #type::size
    nop
    lda (ptr1),z
    nop
    sta (ptr2),z
    inz
    nop
    lda (ptr1),z
    nop
    sta (ptr2),z

    ; Clone the name, if any, so the result type isn't aliased to the
    ; declaration's own type block.
    ldz #type::name
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq RewriteNode
    jsr nameClone
    stq ptr3
    ldz #type::name
    ldx #0
:   lda ptr3,x
    nop
    sta (ptr2),z
    inz
    inx
    cpx #4
    bne :-

RewriteNode:
    ; -------- Rewrite the node from EXPR_CALL to EXPR_CAST. --------
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ; First, free the former left node (EXPR_NAME for the routine call)
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    jsr pushQ
    ldz #expr::name
    neg
    neg
    nop
    lda (ptr1),z
    jsr heapFree
    jsr popQ
    jsr heapFree
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    jsr heapFree

    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    lda #EXPR_CAST
    ldz #expr::kind
    nop
    sta (ptr1),z
    ldz #expr::left
    ldx #0
:   lda argExprPtr,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    lda #0
    ldz #expr::right
    ldx #0
:   nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-

    ; Copy evalTypeKind and evalTypeSize from targetBaseType
    ldq targetBaseType
    stq ptr2
    ldz #type::kind
    nop
    lda (ptr2),z
    ldz #expr::evalTypeKind
    nop
    sta (ptr1),z
    ldz #type::size
    nop
    lda (ptr2),z
    pha
    inz
    nop
    lda (ptr2),z
    pha
    ldz #expr::evalTypeSize+1
    pla
    nop
    sta (ptr1),z
    dez
    pla
    nop
    sta (ptr1),z

    jmp DN

BadArity:
    lda #errWrongNumberOfParams
    jsr typeCheckError
    jmp VoidResult

BadType:
    lda #errInvalidTypeCast
    jsr typeCheckError
    ; Fall through

VoidResult:
    ldz #rtnTypePtrOffset
    jsr loadStackValue
    stq ptr1
    lda #TYPE_VOID
    ldz #type::kind
    nop
    sta (ptr1),z

DN: jsr popQ                   ; return type
    jsr popQ                   ; expression
    rts
.endproc

; This routine sets the Z flag if the TYPE_ kind in A can be used
; as either side of an explicit type-cast expression: any integer
; type, Char, Boolean, an enumeration, or an enumeration value.
.proc isTypeCastable
    jsr isTypeOrdinal
    beq YES
    cmp #TYPE_CHARACTER
    beq YES
    cmp #TYPE_BOOLEAN
    beq YES
    cmp #TYPE_ENUMERATION_VALUE
YES:
    rts
.endproc
