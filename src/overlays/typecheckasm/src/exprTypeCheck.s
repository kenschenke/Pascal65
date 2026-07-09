;
; exprTypeCheck.s
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

rightTypeOffset = 0
leftTypeOffset = rightTypeOffset + .sizeof(type)
parentIsFuncCallOffset = leftTypeOffset + .sizeof(type)
typePtrOffset = parentIsFuncCallOffset + 1
recordSymtabOffset = typePtrOffset + 4
exprOffset = recordSymtabOffset + 4

.export exprTypeCheck

.import loadStackValue, evalArrayLiteral, exprLiteral, typeCheckError
.import isTypeInteger, realOperands, integerOperands, checkRelOpOperands
.import checkBoolOperand, getTypeConversion, getTypeSize, isExprATypeDeclaration
.import isExprAFuncCall, checkAssignment, checkFuncProcCall, getArrayType, hoistFuncCall

.bss

arrayType: .res .sizeof(type)
elemType: .res 4
indexType: .res 4

.code

; Parameters on the stack from bottom to top:
;    Pointer to expression
;    Pointer to record symbol table
;    Pointer to type structure
;    parentIsFuncCall byte (0 or non-zero)
.proc exprTypeCheck
    ; Push the left and right types onto the stack
    lda #.sizeof(type)
    jsr pushBlock
    lda #.sizeof(type)
    jsr pushBlock
    ; Zero out the type ptr
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    lda #0
    taz
:   nop
    sta (ptr1),z
    inz
    cpz #.sizeof(type)
    bne :-

    ; Zero out the left and right type structures on the stack
    ldz #leftTypeOffset
    jsr zeroTypeBlock
    ldz #rightTypeOffset
    jsr zeroTypeBlock

    ; Is the expr null?
    ldz #exprOffset
    jsr loadStackValue
    jsr isQZero
    bne :+
    jmp DN

:   stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_ARRAY_LITERAL
    bne :+
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    jsr evalArrayLiteral
    jmp DN

    ; Evaluate the left expression
:   pha                         ; save the expr kind
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #recordSymtabOffset
    jsr loadStackValue
    stq ptr2
    lda #leftTypeOffset
    jsr calcTypeBlockAddr
    stq ptr3
    ldq ptr1
    jsr pushQ
    ldq ptr2
    jsr pushQ
    ldq ptr3
    jsr pushQ
    pla
    cmp #EXPR_CALL
    beq LF
    cmp #EXPR_ADDRESS_OF
    beq LF
    lda #0
    bra LP
LF: lda #1
LP: jsr pushA
    jsr exprTypeCheck

    ; If the expression is EXPR_ARG then copy the leftType
    ; into the caller's type and set the expr's evalType.

    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_ARG
    beq :+
    jmp L1

    ; Copy the leftType into the caller's type pointer
:   lda #leftTypeOffset
    jsr calcTypeBlockAddr
    stq ptr1
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr2
    ldz #0
:   nop
    lda (ptr1),z
    nop
    sta (ptr2),z
    inz
    cpz #.sizeof(type)
    bne :-

    ; Evaluate the next argument in the chain
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    lda #leftTypeOffset
    jsr calcTypeBlockAddr
    stq ptr2
    ldq ptr1
    jsr pushQ
    jsr pushQZero
    ldq ptr2
    jsr pushQ
    lda #0
    jsr pushA
    jsr exprTypeCheck

    jmp DN

    ; Evaluate the right expression
L1: ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    pha                         ; save the expr kind
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #recordSymtabOffset
    jsr loadStackValue
    stq ptr2
    lda #rightTypeOffset
    jsr calcTypeBlockAddr
    stq ptr3
    ldq ptr1
    jsr pushQ
    ldq ptr2
    jsr pushQ
    ldq ptr3
    jsr pushQ
    pla
    cmp #EXPR_CALL
    beq RF
    lda #0
    bra RC
RF: lda #1
RC: jsr pushA
    jsr exprTypeCheck

    ; Evaluate the expression itself
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_BOOLEAN_LITERAL
    bne :+
    jsr evalLiteral
    jmp DN
:   cmp #EXPR_BYTE_LITERAL
    bne :+
    jsr evalLiteral
    jmp DN
:   cmp #EXPR_WORD_LITERAL
    bne :+
    jsr evalLiteral
    jmp DN
:   cmp #EXPR_DWORD_LITERAL
    bne :+
    jsr evalLiteral
    jmp DN
:   cmp #EXPR_STRING_LITERAL
    bne :+
    jsr evalLiteral
    jmp DN
:   cmp #EXPR_CHARACTER_LITERAL
    bne :+
    jsr evalLiteral
    jmp DN
:   cmp #EXPR_REAL_LITERAL
    bne :+
    jsr evalLiteral
    jmp DN
:   cmp #EXPR_ADD
    bne :+
    jsr evalAdd
    jmp DN
:   cmp #EXPR_SUB
    bne :+
    jsr evalSubMult
    jmp DN
:   cmp #EXPR_MUL
    bne :+
    jsr evalSubMult
    jmp DN
:   cmp #EXPR_DIV
    bne :+
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    lda #TYPE_REAL
    nop
    sta (ptr1),z
    ldz #type::size
    lda #4
    nop
    sta (ptr1),z
    inz
    lda #0
    nop
    sta (ptr1),z
    jmp DN
:   cmp #EXPR_DIVINT
    bne :+
    jsr evalDivIntMod
    jmp DN
:   cmp #EXPR_MOD
    bne :+
    jsr evalDivIntMod
    jmp DN
:   cmp #EXPR_LT
    bne :+
    jsr evalRelOp
    jmp DN
:   cmp #EXPR_LTE
    bne :+
    jsr evalRelOp
    jmp DN
:   cmp #EXPR_GT
    bne :+
    jsr evalRelOp
    jmp DN
:   cmp #EXPR_GTE
    bne :+
    jsr evalRelOp
    jmp DN
:   cmp #EXPR_NE
    bne :+
    jsr evalRelOp
    jmp DN
:   cmp #EXPR_EQ
    bne :+
    jsr evalRelOp
    jmp DN
:   cmp #EXPR_OR
    bne :+
    jsr evalBoolOp
    jmp DN
:   cmp #EXPR_AND
    bne :+
    jsr evalBoolOp
    jmp DN
:   cmp #EXPR_BITWISE_AND
    bne :+
    jsr evalBitwiseOp
    jmp DN
:   cmp #EXPR_BITWISE_OR
    bne :+
    jsr evalBitwiseOp
    jmp DN
:   cmp #EXPR_BITWISE_XOR
    bne :+
    jsr evalBitwiseOp
    jmp DN
:   cmp #EXPR_BITWISE_LSHIFT
    bne :+
    jsr evalBitwiseShift
    jmp DN
:   cmp #EXPR_BITWISE_RSHIFT
    bne :+
    jsr evalBitwiseShift
    jmp DN
:   cmp #EXPR_NOT
    bne :+
    jsr evalNot
    jmp DN
:   cmp #EXPR_ASSIGN
    bne :+
    jsr evalAssign
    jmp DN
:   cmp #EXPR_NAME
    bne :+
    jsr evalName
    jmp DN
:   cmp #EXPR_CALL
    bne :+
    jsr evalCall
    jmp DN
:   cmp #EXPR_ARG
    bne :+
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    lda #TYPE_VOID
    nop
    sta (ptr1),z
    jmp DN
:   cmp #EXPR_SUBSCRIPT
    bne :+
    jsr evalSubscript
    jmp DN
:   cmp #EXPR_FIELD
    bne :+
    jsr evalField
    jmp DN
:   cmp #EXPR_ARRAY_LITERAL
    bne :+
    ; Do nothing here. This is checked in decl_typecheck.
    jmp DN
:   cmp #EXPR_ADDRESS_OF
    bne :+
    jsr evalAddressOf
    jmp DN
:   cmp #EXPR_POINTER
    bne :+
    jsr evalPointer
    jmp DN
:   lda #errInvalidType
    jsr typeCheckError
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    lda #TYPE_VOID
    ldz #type::kind
    nop
    sta (ptr1),z
    ; Fall through to DN

DN:
    ; Don't bother saving evalType if expr is NULL
    ldz #exprOffset
    jsr loadStackValue
    jsr isQZero
    beq :+
    ; Save the evalType back into the expression
    jsr saveEvalType
    ; Clean up local variables and parameters off the stack
:   ; Free subtypes in local types
    lda #leftTypeOffset
    jsr freeTempType
    lda #rightTypeOffset
    jsr freeTempType
    lda #.sizeof(type)
    jsr popBlock
    lda #.sizeof(type)
    jsr popBlock
    jsr popA
    jsr popQ
    jsr popQ
    jsr popQ
    rts
.endproc

; Stack offset of block passed in Z.
.proc zeroTypeBlock
    ldx #.sizeof(type)
    lda #0
:   nop
    sta (stackPointer),z
    inz
    dex
    bne :-
    rts
.endproc

; This routine frees any subtype and name that might have been allocated
; for the local type variables
;
; Type offset passed in A
.proc freeTempType
    jsr calcTypeBlockAddr
    stq ptr1
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    stq ptr1
    ldz #type::flags
    nop
    lda (ptr1),z
    and #TYPE_FLAG_ISTEMP
    beq :+
    ldq ptr1
    jsr freeType
:   rts
.endproc

; This routine calculates the address of the type block on the
; runtime stack. The offset of the block is passed in A.
; The address of the type block is returned in Q.
.proc calcTypeBlockAddr
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq stackPointer
    clc
    adcq intOp32
    rts
.endproc

.proc evalLiteral
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr2
    ldq ptr1
    jsr pushQ
    ldq ptr2
    jsr pushQ
    jsr exprLiteral
    ; jsr saveEvalType
    rts
.endproc

.proc saveEvalType
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::evalType
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    jsr freeType
:   ldz #typePtrOffset
    jsr loadStackValue
    jsr typeClone
    stq ptr2
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::evalType
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

; This routine loads the arguments for a call to
; realOperands or integerOperands. They take the same arguments.
.proc loadMathOperandsArgs
    lda #rightTypeOffset
    jsr calcTypeBlockAddr
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    pha
    lda #leftTypeOffset
    jsr calcTypeBlockAddr
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    pha
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    pla
    jsr pushA
    pla
    jsr pushA
    ldq ptr1
    jsr pushQ
    rts
.endproc

; This routine copies the type pointed at by Q
; to the leftType on the stack. The type offset is passed in Z.
.proc copyToType
    phz
    ldz #0
    stq ptr2
    pla
    jsr calcTypeBlockAddr
    stq ptr1
    ldz #0
:   nop
    lda (ptr2),z
    nop
    sta (ptr1),z
    inz
    cpz #.sizeof(type)
    bne :-
    rts
.endproc

.proc evalAdd
    ; If the left and right operands are valid for concatenation then
    ; the result is a string object.
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    jsr isConcatOperand
    bne L1
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    jsr isConcatOperand
    bne L1
    ; The result is a string object
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    lda #TYPE_STRING_OBJ
    nop
    sta (ptr1),z
    ldz #type::size
    lda #2
    nop
    sta (ptr1),z
    inz
    lda #0
    sta (ptr1),z
    rts

    ; Is this expression pointer arithmetic?
L1: lda #leftTypeOffset
    jsr calcTypeBlockAddr
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_POINTER
    bne L2
    lda #rightTypeOffset
    jsr calcTypeBlockAddr
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    jsr isTypeInteger
    beq :+
    lda #errIncompatibleTypes
    jsr typeCheckError
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    lda #TYPE_VOID
    nop
    sta (ptr1),z
    rts
:   ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    lda #TYPE_ADDRESS
    nop
    sta (ptr1),z
    rts

    ; Addition
L2: jsr loadMathOperandsArgs
    jsr realOperands
    rts
.endproc

.proc evalDivIntMod
    jsr loadMathOperandsArgs
    jsr integerOperands
    rts
.endproc

.proc evalSubMult
    lda #leftTypeOffset
    jsr calcTypeBlockAddr
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_POINTER
    bne L5
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_SUB
    bne L1
    lda #rightTypeOffset
    jsr calcTypeBlockAddr
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    jsr isTypeInteger
    bne L1

    ; Address-of
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    lda #TYPE_ADDRESS
    nop
    sta (ptr1),z
    rts

    ; Incompatible type
L1: lda #errIncompatibleTypes
    jsr typeCheckError
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    lda #TYPE_VOID
    nop
    sta (ptr1),z
    rts

L5: jsr loadMathOperandsArgs
    jsr realOperands
    rts
.endproc

.proc evalRelOp
    lda #leftTypeOffset
    jsr calcTypeBlockAddr
    stq ptr1
    lda #rightTypeOffset
    jsr calcTypeBlockAddr
    stq ptr2
    ldq ptr1
    jsr pushQ
    ldq ptr2
    jsr pushQ
    jsr checkRelOpOperands
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    lda #TYPE_BOOLEAN
    nop
    sta (ptr1),z
    ldz #type::size
    lda #1
    nop
    sta (ptr1),z
    inz
    lda #0
    nop
    sta (ptr1),z
    rts
.endproc

.proc evalBoolOp
    lda #leftTypeOffset
    jsr calcTypeBlockAddr
    jsr checkBoolOperand
    lda #rightTypeOffset
    jsr calcTypeBlockAddr
    jsr checkBoolOperand
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    lda #TYPE_BOOLEAN
    nop
    sta (ptr1),z
    ldz #type::size
    lda #1
    nop
    sta (ptr1),z
    inz
    lda #0
    nop
    sta (ptr1),z
    rts
.endproc

.proc evalBitwiseOp
    lda #rightTypeOffset
    jsr calcTypeBlockAddr
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    pha
    lda #leftTypeOffset
    jsr calcTypeBlockAddr
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    plx
    jsr getTypeConversion
    pha
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    pla
    nop
    sta (ptr1),z
    cmp #TYPE_VOID
    bne :+
    lda #errIncompatibleTypes
    jsr typeCheckError
    rts
:   ldz #type::kind
    nop
    lda (ptr1),z
    jsr getTypeSize
    ldz #type::size
    nop
    sta (ptr1),z
    inz
    txa
    nop
    sta (ptr1),z
    rts
.endproc

.proc evalBitwiseShift
    lda #leftTypeOffset
    jsr calcTypeBlockAddr
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    jsr isTypeInteger
    bne L1
    lda #rightTypeOffset
    jsr calcTypeBlockAddr
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    jsr isTypeInteger
    bne L1

    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    lda #leftTypeOffset
    jsr calcTypeBlockAddr
    stq ptr2
    ldz #type::kind
    nop
    lda (ptr2),z
    nop
    sta (ptr1),z
    ldz #type::size
    nop
    lda (ptr2),z
    nop
    sta (ptr1),z
    inz
    nop
    lda (ptr2),z
    nop
    sta (ptr1),z
    rts

L1: lda #errInvalidType
    jsr typeCheckError
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    lda #TYPE_VOID
    nop
    sta (ptr1),z
    rts
.endproc

.proc evalNot
    lda #leftTypeOffset
    jsr calcTypeBlockAddr
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_BOOLEAN
    bne L1
    ; Logical not
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    lda #TYPE_BOOLEAN
    nop
    sta (ptr1),z
    ldz #type::size
    lda #1
    nop
    sta (ptr1),z
    inz
    lda #0
    nop
    sta (ptr1),z
    rts

L1: jsr isTypeInteger
    bne L2
    ; Bitwise complement
    lda #leftTypeOffset
    jsr calcTypeBlockAddr
    stq ptr2
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr2),z
    nop
    sta (ptr1),z
    ldz #type::size
    nop
    lda (ptr2),z
    nop
    sta (ptr1),z
    inz
    nop
    lda (ptr2),z
    nop
    sta (ptr1),z
    rts

L2: lda #errIncompatibleTypes
    jsr typeCheckError
    rts
.endproc

.proc evalAssign
    ldz #exprOffset
    jsr loadStackValue
    jsr isExprATypeDeclaration
    bne L1
    lda #errInvalidIdentifierUsage
    jsr typeCheckError
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    lda #TYPE_VOID
    nop
    sta (ptr1),z
    rts

L1: ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    jsr isExprAFuncCall
    bne L2
    lda #errInvalidIdentifierUsage
    jsr typeCheckError
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    lda #TYPE_VOID
    nop
    sta (ptr1),z
    rts

L2: lda #leftTypeOffset
    jsr calcTypeBlockAddr
    stq ptr1
    ldz #type::flags
    nop
    lda (ptr1),z
    and #TYPE_FLAG_ISCONST
    bne L3
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ENUMERATION_VALUE
    bne L4

L3: lda #errIncompatibleAssignment
    jsr typeCheckError
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    lda #TYPE_VOID
    nop
    sta (ptr1),z
    rts

L4: lda #leftTypeOffset
    jsr calcTypeBlockAddr
    jsr getBaseType
    ldz #leftTypeOffset
    jsr copyToType
    lda #rightTypeOffset
    jsr calcTypeBlockAddr
    jsr getBaseType
    ldz #rightTypeOffset
    jsr copyToType

    lda #leftTypeOffset
    jsr calcTypeBlockAddr
    stq ptr1
    lda #rightTypeOffset
    jsr calcTypeBlockAddr
    stq ptr2
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr3
    ldz #exprOffset
    jsr loadStackValue
    stq ptr4
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr4),z
    stq ptr4
    ldq ptr1
    jsr pushQ
    ldq ptr2
    jsr pushQ
    ldq ptr3
    jsr pushQ
    ldq ptr4
    jsr pushQ
    jsr checkAssignment
    rts
.endproc

.proc evalPointer
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::evalType
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L1
    ldz #leftTypeOffset
    jsr copyToType
    bra L2

L1: ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #expr::evalType
    neg
    neg
    nop
    lda (ptr1),z
    ldz #leftTypeOffset
    jsr copyToType

L2: lda #leftTypeOffset
    jsr calcTypeBlockAddr
    stq ptr1
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L3
    ldz #leftTypeOffset
    jsr copyToType

L3: lda #leftTypeOffset
    jsr calcTypeBlockAddr
    stq ptr2
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr2),z
    nop
    sta (ptr1),z
    ; Copy name from type in ptr2 to type in ptr1
    ldz #type::name
    ldx #0
:   nop
    lda (ptr2),z
    nop
    sta (ptr1),z
    inz
    inx
    cpx #NAMELEN
    bne :-
L4: rts
.endproc

.proc evalAddressOf
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1

    lda #leftTypeOffset
    jsr calcTypeBlockAddr
    stq ptr2
    ldz #type::kind
    nop
    lda (ptr2),z
    cmp #TYPE_PROCEDURE
    beq L1
    cmp #TYPE_FUNCTION
    beq L1
    lda #TYPE_ADDRESS
    bra L2
L1: lda #TYPE_ROUTINE_ADDRESS
L2: ldz #type::kind
    nop
    sta (ptr1),z

    ldz #type::kind
    nop
    lda (ptr2),z
    jsr pushA
    lda #0
    jsr pushA
    jsr pushQZero
    jsr pushQZero
    jsr typeCreate
    stq ptr2
    ldz #type::flags
    nop
    lda (ptr2),z
    ora #TYPE_FLAG_ISTEMP
    nop
    sta (ptr2),z

    ldz #typePtrOffset
    jsr loadStackValue
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

.proc evalField
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    jsr isExprATypeDeclaration
    bne L1
    lda #errInvalidIdentifierUsage
    jsr typeCheckError
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    lda #TYPE_VOID
    nop
    sta (ptr1),z
    rts

    ; Grab the symbol table from the left child
L1: ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::node
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    jmp L8

:   ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
L2: ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_FIELD
    beq L3
    cmp #EXPR_SUBSCRIPT
    bne L4

L3: ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    bra L2

L4: ldz #expr::node
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    bne L5
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_POINTER
    bne L5
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1

L5: ldz #expr::node
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr2),z
    ldz #rightTypeOffset
    jsr copyToType
    ; Call exprTypeCheck
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    lda #rightTypeOffset
    jsr calcTypeBlockAddr
    stq ptr2
    ldz #type::symtab
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr3
    ldq ptr1
    jsr pushQ
    ldq ptr2
    jsr pushQ
    ldq ptr3
    jsr pushQ
    lda #0
    jsr pushA
    jsr exprTypeCheck
    lda #rightTypeOffset
    jsr calcTypeBlockAddr
    stq ptr2
    ldz #type::symtab
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::symtab
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    rts

L8: stq ptr2
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #type::symtab
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr3
    ldq ptr1
    jsr pushQ
    ldq ptr2
    jsr pushQ
    ldq ptr3
    jsr pushQ
    lda #0
    jsr pushA
    jsr exprTypeCheck
    lda #rightTypeOffset
    jsr calcTypeBlockAddr
    stq ptr2
    ldz #type::symtab
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::symtab
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

.proc evalSubscript
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    lda #<arrayType
    ldx #>arrayType
    ldy #0
    ldz #0
    jsr pushQ
    jsr getArrayType
    lda #<arrayType
    ldx #>arrayType
    ldy #0
    ldz #0
    jsr getBaseType
    stq ptr2
    lda #<arrayType
    ldx #>arrayType
    ldy #0
    ldz #0
    stq ptr1
    ldz #0
:   nop
    lda (ptr2),z
    nop
    sta (ptr1),z
    inz
    cpz #.sizeof(type)
    bne :-
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_STRING_VAR
    beq L1
    cmp #TYPE_ARRAY
    beq L2
    lda #errInvalidType
    jsr typeCheckError
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    lda #TYPE_VOID
    nop
    sta (ptr1),z
    rts

    ; String var
L1: ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #expr::evalType
    neg
    neg
    nop
    lda (ptr1),z
    jsr getBaseType
    stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    jsr isTypeInteger
    beq TC
    lda #errInvalidIndexType
    jsr typeCheckError
    lda #TYPE_VOID
    bra ST
TC: lda #TYPE_CHARACTER
ST: pha
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    pla
    ldz #type::kind
    nop
    sta (ptr1),z
    rts

L2: lda #<arrayType
    sta ptr1
    lda #>arrayType
    sta ptr1+1
    lda #0
    sta ptr1+2
    sta ptr1+3
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jsr getBaseType
    stq elemType
    lda #<arrayType
    sta ptr1
    lda #>arrayType
    sta ptr1+1
    lda #0
    sta ptr1+2
    sta ptr1+3
    ldz #type::indextype
    neg
    neg
    nop
    lda (ptr1),z
    jsr getBaseType
    stq indexType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ENUMERATION
    beq L4
    cmp #TYPE_ENUMERATION_VALUE
    bne L3
L4: lda #rightTypeOffset
    jsr calcTypeBlockAddr
    jsr getBaseType
    stq ptr2
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    ldq indexType
    stq ptr1
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldx #0
:   lda ptr1,x
    cmp ptr2,x
    bne :+
    inx
    cpx #4
    bne :-
    bra L5
:   lda #errInvalidIndexType
    jsr typeCheckError
    bra L5

    ; else if (rightType.kind != indexType.kind)
L3: lda #rightTypeOffset
    jsr calcTypeBlockAddr
    stq ptr1                    ; rightType in ptr1
    ldq indexType
    stq ptr2                    ; indexType in ptr2
    ldz #type::kind
    nop
    lda (ptr1),z
    nop
    cmp (ptr2),z
    beq L5
    jsr isTypeInteger           ; rightType.kind
    bne L6
    ldz #type::kind
    nop
    lda (ptr2),z
    jsr isTypeInteger           ; indexType.kind
    bne L6
    ldz #type::kind
    nop
    lda (ptr2),z
    tax
    nop
    lda (ptr1),z
    jsr getTypeConversion
    cmp #TYPE_VOID
    bne L5

    ; Error(errInvalidIndexType)
L6: lda #errInvalidIndexType
    jsr typeCheckError

    ; Set typePtr = elemType
L5: ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1                    ; pType in ptr1
    ldq elemType
    stq ptr2                    ; elemType in ptr2
    ldz #type::kind
    nop
    lda (ptr2),z
    nop
    sta (ptr1),z
    ldz #type::flags
    nop
    lda (ptr2),z
    and #TYPE_FLAG_ISCONST
    nop
    sta (ptr1),z
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr3
    ldx #0
    ldz #type::subtype
:   lda ptr3,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    ldz #type::symtab
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr3
    ldx #0
    ldz #type::symtab
:   lda ptr3,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    rts
.endproc

.proc evalCall
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr2
    ldq ptr1
    jsr pushQ
    ldq ptr2
    jsr pushQ
    jsr checkFuncProcCall
    rts
.endproc

.proc evalName
    ; Look up the node
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::node
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    bne :+
    lda #errUndefinedIdentifier
    jsr typeCheckError
    rts
:   stq ptr1
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr3                    ; symbol type in ptr3
    ldz #leftTypeOffset
    jsr copyToType
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    bne L1
    ldz #type::subtype
    ldx #0
:   lda ptr3,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
L1: lda #leftTypeOffset
    jsr calcTypeBlockAddr
    stq ptr3
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr3),z
    nop
    sta (ptr1),z
    ldz #type::flags
    nop
    lda (ptr3),z
    nop
    sta (ptr1),z
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr4
    ldz #type::subtype
    ldx #0
:   lda ptr4,x
    nop
    sta (ptr1),z
    inx
    inz
    cpx #4
    bne :-
    ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr4
    ldz #type::paramFields
    ldx #0
:   lda ptr4,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    ldz #type::size
    nop
    lda (ptr3),z
    nop
    sta (ptr1),z
    inz
    nop
    lda (ptr3),z
    nop
    sta (ptr1),z
    ldz #type::kind
    nop
    lda (ptr3),z
    cmp #TYPE_ARRAY
    bne L2
    ldz #type::indextype
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr4
    ldz #type::indextype
    ldx #0
:   lda ptr4,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
L2: ldz #type::kind
    nop
    lda (ptr3),z
    cmp #TYPE_FUNCTION
    bne L3
    ldz #parentIsFuncCallOffset
    nop
    lda (stackPointer),z
    bne L3
    ldz #exprOffset
    jsr loadStackValue
    jsr hoistFuncCall
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr2
    ldq ptr1
    jsr pushQ
    ldq ptr2
    jsr pushQ
    jsr checkFuncProcCall
L3: rts
.endproc
