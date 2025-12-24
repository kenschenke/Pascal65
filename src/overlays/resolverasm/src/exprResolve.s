;
; exprResolve.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; exprResolve routine

.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

leftSymtabOffset = 0
isRtnCallOffset = 4
symtabOffset = 5
exprOffset = 9

.export exprResolve

.import resolverError, getRecordSymtab

; Runtime stack entry, bottom to top:
;    expr ptr
;    symtab ptr
;    isRtnCall
.proc exprResolve
    jsr pushQZero           ; leftSymtab
    ldz #exprOffset
    neg
    neg
    nop
    lda (stackPointer),z
    jsr isQZero
    bne :+
    jmp L9

    ; If this is a function call and the symbol
    ; is the return value, need to look up the function
    ; in the parent scope
:   stq ptr1                ; expr pointer was still in Q
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_NAME
    beq :+
    jmp L5

:   ldz #expr::name
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr4                ; name in ptr4

    ldz #symtabOffset
    neg
    neg
    nop
    lda (stackPointer),z
    jsr isQZero
    beq L1                  ; symtab is null
    stq ptr1
    jsr symtabLookup
    jsr isQZero
    beq :+
    stq ptr2                ; symbol table node in ptr2
    bra L4
    ; Name not found in the symbol table
:   lda #errUndefinedIdentifier
    jsr resolverError
    jmp L9

    ; Symbol table is null
L1: jsr scopeLookup
    jsr isQZero
    bne :+
    lda #errUndefinedIdentifier
    jsr resolverError
    jmp L9
:   stq ptr2                ; symbol table node in ptr2
    ldz #isRtnCallOffset
    nop
    lda (stackPointer),z
    beq L4
    ; Look up the symbol table node's type
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr3
    ldz #type::flags
    nop
    lda (ptr3),z
    and #TYPE_FLAG_ISRETVAL
    beq L4
    ; This is a return value type. Look in the parent scope
    jsr scopeLookupParent
    jsr isQZero
    bne L4
    lda #errUndefinedIdentifier
    jsr resolverError
    jmp L9

    ; Set the expression's node to the symbol table node
L4: ldz #exprOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #expr::node
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    jmp L9

    ; If this is a EXPR_FIELD we need to resolve the right child using
    ; the record's symbol table instead of the scope stack.
L5: cmp #EXPR_FIELD
    bne L7
    ; Look up the record symtab
    ldz #symtabOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr2
    ldz #exprOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ               ; expression
    ldq ptr2
    jsr pushQ               ; symtab
    jsr getRecordSymtab
    stq ptr3
    ldz #leftSymtabOffset
    ldx #0
:   lda ptr3,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-

    ; Resolve the left and right child of the expression
L7: ldz #exprOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2                ; left in ptr2
    ldz #symtabOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr3                ; symtab in ptr3
    ldx #0
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_CALL
    bne :+
    ldx #1
:   stx tmp1                ; isRtnCall in tmp1
    ldq ptr2
    jsr pushQ               ; expr ptr
    ldq ptr3
    jsr pushQ               ; symtab
    lda tmp1
    jsr pushA               ; isRtnCall
    jsr exprResolve
    ; Resolve right expression
    ldz #symtabOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr2
    ldz #exprOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ               ; right expr pointer
    ldq ptr2
    jsr pushQ               ; symtab
    lda #0
    jsr pushA               ; isRtnCall
    jsr exprResolve

L9: jsr popQ
    jsr popA
    jsr popQ
    jsr popQ
    rts
.endproc
