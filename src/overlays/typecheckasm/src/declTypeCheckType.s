;
; declTypeCheckType.s
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

typeOffset = 0
declOffset = 4

.export declTypeCheckType

.bss

fwdType: .res 4                 ; forward declaration's type
fwdReturn: .res 4               ; its return type

.code

.import checkArray, checkForwardVsFormalDeclaration, loadStackValue, calcNamePtr
.import typeCheckError

.proc declTypeCheckType
    ; If this is an array make sure the index type is
    ; an integer, enum, or character and the element type is not a string.
    ; Only do the check if this is a variable and the type
    ; is an anonymous type (defined inline) or this declaration
    ; is the array type (Type section).

    stq ptr1                ; type in ptr1
    jsr pushQ
    ldz #declOffset
    jsr loadStackValue
    stq ptr2                ; decl in ptr2

    ; if (decl.kind == DECL_VARIABLE && type.name == null)
    ldz #decl::kind
    nop
    lda (ptr2),z
    cmp #DECL_VARIABLE
    bne L1
    ldz #type::name
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    bne L3
L1: ; if (decl.kind == DECL_TYPE)
    cmp #DECL_TYPE
    bne L3

    ; if (type.kind == TYPE_ARRAY)
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ARRAY
    bne L3

    ; check the array
    ldz #type::indextype
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    jsr checkArray

    ; A file can't hold dynamic arrays (File Of Array Of T). Only the
    ; header would be read or written. A clone is the type of a variable
    ; of a named file type, which was checked at the type's declaration.
L3: ldz #typeOffset
    jsr loadStackValue
    stq ptr1                ; type in ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_FILE
    bne L6
    ldz #type::flags
    nop
    lda (ptr1),z
    and #TYPE_FLAG_ISCLONED
    bne L6
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L6
    jsr getBaseType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ARRAY
    bne L6
    ldz #type::flags
    nop
    lda (ptr1),z
    and #TYPE_FLAG_ISDYNAMIC
    beq L6
    lda #errDynArrayInFile
    jsr typeCheckError

    ; A function can't return an array, static or dynamic
L6: ldz #typeOffset
    jsr loadStackValue
    stq ptr1                ; type in ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_FUNCTION
    bne L5
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L5
    jsr getBaseType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ARRAY
    bne L5
    lda #errArrayReturnType
    jsr typeCheckError

    ; If this is a function or procedure, check for a forward declaration and make
    ; sure the forward declaration matches the formal declaration.
L5: ldz #typeOffset
    jsr loadStackValue
    stq ptr1                ; type in ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_FUNCTION
    beq :+
    cmp #TYPE_PROCEDURE
    bne L4
:   ldz #type::flags
    nop
    lda (ptr1),z
    and #TYPE_FLAG_ISFORWARD
    bne L4
    ldz #declOffset
    jsr loadStackValue
    stq ptr2                ; decl in ptr2
    ldz #decl::name
    jsr calcNamePtr
    stq ptr4
    jsr scopeLookup
    jsr isQZero
    beq L4
    stq ptr3                ; symbol in ptr3
    ; The resolver points symbol::decl at the formal declaration,
    ; but symbol::type is a clone of the first (forward) declaration's
    ; type and shares its parameter list.
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr3),z
    jsr isQZero
    beq L4
    stq ptr2                ; forward declaration's type in ptr2
    stq fwdType
    ldz #typeOffset
    jsr loadStackValue
    stq ptr1                ; type in ptr1
    ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr2),z
    jsr pushQ
    ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    jsr checkForwardVsFormalDeclaration

    ; A function's return types must match too
    ldz #typeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_FUNCTION
    bne L4
    jsr checkReturnTypes

L4: jsr popQ
    rts
.endproc

; This routine compares the return type of the formal declaration
; (the type at the top of the runtime stack) with the forward
; declaration's (fwdType). A return type is always a type
; name, so the same name gives the same base type.
.proc checkReturnTypes
    ldq fwdType
    stq ptr1
    jsr getSubtype
    jsr isQZero
    beq DN
    jsr getBaseType
    stq fwdReturn
    ldz #typeOffset
    jsr loadStackValue
    stq ptr1
    jsr getSubtype
    jsr isQZero
    beq DN
    jsr getBaseType
    stq ptr2                ; formal return type in ptr2
    ldq fwdReturn
    stq ptr1                ; forward return type in ptr1

    ; The kinds must match
    ldz #type::kind
    nop
    lda (ptr1),z
    nop
    cmp (ptr2),z
    bne ER

    ; An enumeration or record must be the same type. The forward
    ; declaration's type can be a clone, but a clone shares its values
    ; or fields (paramFields).
    cmp #TYPE_ENUMERATION
    beq :+
    cmp #TYPE_RECORD
    bne DN
:   ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr1),z
    stq fwdReturn
    ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    ldx #0
:   lda fwdReturn,x
    cmp ptr2,x
    bne ER
    inx
    cpx #4
    bne :-
DN: rts

ER: lda #errIncompatibleTypes
    jmp typeCheckError
.endproc

; This routine returns the subtype of the type in ptr1 in Q.
.proc getSubtype
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    rts
.endproc
