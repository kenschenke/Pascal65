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

.import checkArray, checkForwardVsFormalDeclaration, loadStackValue, calcNamePtr

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

    ; If this is a function or procedure, check for a forward declaration and make
    ; sure the forward declaration matches the formal declaration.
L3: ldz #typeOffset
    jsr loadStackValue
    stq ptr1                ; type in ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_FUNCTION
    bne L4
    cmp #TYPE_PROCEDURE
    bne L4
    ldz #type::flags
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
    stq ptr3                ; symbol in ptr3
    ldz #symbol::decl
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr2                ; symbol's decl in ptr2
    ldz #decl::type
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2                ; symbol's decl's type in ptr2
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

L4: jsr popQ
    rts
.endproc
