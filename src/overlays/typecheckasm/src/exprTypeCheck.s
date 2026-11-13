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
.import isTypeInteger, realOperands, checkRelOpOperands
.import checkBoolOperand, getTypeConversion, getTypeSize, isExprATypeDeclaration
.import isExprAFuncCall, checkAssignment, checkFuncProcCall, getArrayType, hoistFuncCall
.import checkTypeCast, isExprARoutineCall, getBinaryExpressionType
.import isTypeCastable, getRecordSymtab

.bss

arrayType: .res .sizeof(type)
elemType: .res 4
indexType: .res 4
addrSymtab: .res 4         ; a record's table for evalAddressOf
ptrPointee: .res 4         ; what a pointer points to, for evalPointer
ptrBase: .res 4            ; and its base type
rebaseOff: .res 1          ; a type block's offset, for rebaseType
rebaseName: .res 4         ; and its name before

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

    ; An argument checked on its own (parentIsFuncCall 2) doesn't check the
    ; ones after it
    ldz #parentIsFuncCallOffset
    nop
    lda (stackPointer),z
    cmp #2
    bne :+
    jmp DN

    ; Check the arguments after it in a loop, not a recursive call: a long
    ; chain would overflow the CPU stack. Each is checked on its own into
    ; this frame's leftType, which only needs zeroing after: its type is
    ; the caller's now, and each argument's frame frees its own.
:   ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ                   ; the next argument
NA: ldz #0
    jsr loadStackValue
    jsr isQZero
    beq ND
    stq ptr1
    lda #leftTypeOffset+4
    jsr calcTypeBlockAddr
    stq ptr2
    ldq ptr1
    jsr pushQ
    jsr pushQZero
    ldq ptr2
    jsr pushQ
    lda #2
    jsr pushA
    jsr exprTypeCheck
    ldz #0
    jsr loadStackValue
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #0
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    bra NA
ND: jsr popQ
    ldz #leftTypeOffset
    jsr zeroTypeBlock
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
:   cmp #EXPR_CAST
    bne :+
    jsr evalCast
    jmp DN
:   cmp #EXPR_NEGATE
    bne :+
    jsr evalNegate
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
    jsr pushQ
    ldz #type::name
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    jsr heapFree
:   jsr popQ
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
    stq ptr1                    ; expression in ptr1

    ; Skip this for EXPR_CAST
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_CAST
    bne :+
    rts

:   ldz #typePtrOffset
    jsr loadStackValue
    stq ptr2                    ; type in ptr2

    ; Set the evalTypeSize
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
    pla
    dez
    nop
    sta (ptr1),z

    ; Set the evalTypeFlags. TYPE_FLAG_ISDYNAMIC shares its bit with
    ; TYPE_FLAG_CONCAT, which means something else in an expression.
    ldz #type::flags
    nop
    lda (ptr2),z
    and #<~TYPE_FLAG_ISDYNAMIC
    ldz #expr::evalTypeFlags
    nop
    sta (ptr1),z

    ; Set the evalTypeKind
    ldq ptr1
    jsr pushQ
    ldq ptr2
    jsr getBaseType
    stq ptr2
    jsr popQ
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr2),z
    ldz #expr::evalTypeKind
    nop
    sta (ptr1),z

    ; Is expr kind EXPR_POINTER?
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_POINTER
    beq PFS                 ; branch if EXPR_POINTER
    cmp #EXPR_FIELD
    beq PFS                 ; branch if EXPR_FIELD
    cmp #EXPR_SUBSCRIPT
    beq PFS                 ; branch if EXPR_SUBSCRIPT
    bra PT

    ; The result of a pointer, field, or subscript expression is only ever
    ; looked at again when it is a pointer, record, array, or string. A
    ; number or Boolean doesn't need its own copy of the type.
PFS:
    ldz #expr::evalTypeKind
    nop
    lda (ptr1),z
    cmp #TYPE_BYTE
    bcc L1
    cmp #TYPE_BOOLEAN+1
    bcs L1
    rts

PT: ldz #typePtrOffset
    jsr loadStackValue
    ; jsr getBaseType
    stq ptr2                    ; type in ptr2

    ; Is type TYPE_POINTER?
    ldz #type::kind
    nop
    lda (ptr2),z
    cmp #TYPE_POINTER
    beq L1                  ; branch if TYPE_POINTER

    ; Is this a concat operand?
    jsr isConcatType
    bne NC                  ; branch if not a concat type

    ; Plain characters and string objects don't need their own copy of the
    ; type. The expression's evalTypeKind and evalTypeSize are enough. Mark
    ; the expression so isConcatOperand still recognizes it. Character arrays
    ; and string variables are still cloned.
    ldq ptr2
    jsr getBaseType
    stq ptr2
    ldz #type::kind
    nop
    lda (ptr2),z
    cmp #TYPE_CHARACTER
    beq NoClone
    cmp #TYPE_STRING_LITERAL
    beq NoClone
    cmp #TYPE_STRING_OBJ
    beq NoClone
    jmp L1

NoClone:
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::evalTypeFlags
    nop
    lda (ptr1),z
    ora #TYPE_FLAG_CONCAT
    nop
    sta (ptr1),z
    rts

    ; Is type TYPE_RECORD
NC: ldq ptr2
    jsr getBaseType
    stq ptr2
    ldz #type::kind
    nop
    lda (ptr2),z
    cmp #TYPE_RECORD
    beq L1                  ; branch if TYPE_RECORD
    cmp #TYPE_ARRAY
    beq L1                  ; branch if TYPE_ARRAY

    rts

    ; Clone the type
L1: ldz #exprOffset
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

.proc isConcatType
    ; Preserve ptr1 and ptr2
    ldq ptr1
    jsr pushQ
    ldq ptr2
    jsr pushQ

    ldq ptr2
    jsr getBaseType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ARRAY
    bne :+
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jsr getBaseType
    stq ptr1

:   ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_CHARACTER
    beq DN
    cmp #TYPE_STRING_LITERAL
    beq DN
    cmp #TYPE_STRING_OBJ
    beq DN
    cmp #TYPE_STRING_VAR
DN: php
    jsr popQ
    stq ptr2
    jsr popQ
    stq ptr1
    plp
    rts
.endproc

; This routine loads the arguments to getBinaryExpressionType
.proc loadBinaryExpressionArgs
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr2
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    ldq ptr2
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

    ; Clone the name
    ldq ptr3
    jsr pushQ
    ldq ptr4
    jsr pushQ

    ldq ptr1
    ldz #type::name
    neg
    neg
    nop
    lda (ptr2),z
    jsr isQZero
    beq DN
    stq ptr2
    ldq ptr1
    jsr pushQ
    ldq ptr2
    jsr nameClone
    stq ptr2
    jsr popQ
    stq ptr1
    ldx #0
    ldz #type::name
:   lda ptr2,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-

DN: jsr popQ
    stq ptr4
    jsr popQ
    stq ptr3
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
L2: jsr loadBinaryExpressionArgs
    jsr getBinaryExpressionType
    rts
.endproc

.proc evalDivIntMod
    jsr loadBinaryExpressionArgs
    jsr getBinaryExpressionType
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

L5: jsr loadBinaryExpressionArgs
    jsr getBinaryExpressionType
    rts
.endproc

.proc evalRelOp
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr3
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr4
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
    ldq ptr3
    jsr pushQ
    ldq ptr4
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
    jsr loadBinaryExpressionArgs
    jsr getBinaryExpressionType
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

; This routine sets the type of a unary minus (EXPR_NEGATE). A signed
; integer or a real keeps its type. An unsigned integer becomes the signed
; type that holds its negated values: Byte is Integer and Word is LongInt.
; Cardinal is LongInt too, which holds the negated values up to 2^31.
; Anything else is an error.
.proc evalNegate
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #expr::evalTypeKind
    nop
    lda (ptr1),z
    ldx #1
    cmp #TYPE_SHORTINT
    beq ST
    ldx #2
    cmp #TYPE_INTEGER
    beq ST
    cmp #TYPE_BYTE
    bne :+
    lda #TYPE_INTEGER
    bra ST
:   ldx #4
    cmp #TYPE_LONGINT
    beq ST
    cmp #TYPE_REAL
    beq ST
    cmp #TYPE_WORD
    beq LI
    cmp #TYPE_CARDINAL
    bne ER
LI: lda #TYPE_LONGINT

ST: pha
    phx
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::size
    pla
    nop
    sta (ptr1),z
    inz
    lda #0
    nop
    sta (ptr1),z
    ldz #type::kind
    pla
    nop
    sta (ptr1),z
    rts

ER: lda #errIncompatibleTypes
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

; The left of an assignment can't be a type or a function call.
.proc evalAssign
    jsr loadAssignLeft
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

L1: jsr loadAssignLeft
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
    jsr rebaseType
    lda #rightTypeOffset
    jsr rebaseType

    ; An array can't be assigned as a whole, only its elements
    lda #leftTypeOffset
    jsr calcTypeBlockAddr
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ARRAY
    bne L5
    lda #errArrayAssignment
    jsr typeCheckError
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    lda #TYPE_VOID
    nop
    sta (ptr1),z
    rts

L5: lda #leftTypeOffset
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

; This routine checks a cast by a type keyword, such as Integer(x). The
; parser sets its evalTypeKind. What is cast must be castable, as for a
; cast by a type name (checkTypeCast).
; This routine replaces the type in the block at the offset in A with its
; base type. The block's name is a copy (freeTempType frees it), and
; copyToType puts a copy of the base type's in its place, so the old one
; is freed after: the base type can be the block itself.
.proc rebaseType
    sta rebaseOff
    jsr calcTypeBlockAddr
    stq ptr1
    ldz #type::name
    neg
    neg
    nop
    lda (ptr1),z
    stq rebaseName
    lda rebaseOff
    jsr calcTypeBlockAddr
    jsr getBaseType
    ldz rebaseOff
    jsr copyToType
    ldq rebaseName
    jsr isQZero
    beq :+
    jsr heapFree
:   rts
.endproc

.proc evalCast
    lda #leftTypeOffset
    jsr calcTypeBlockAddr
    jsr getBaseType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    jsr isTypeCastable
    beq :+
    lda #errInvalidTypeCast
    jsr typeCheckError
:   rts
.endproc

; This routine loads the left of the assignment expression into Q
.proc loadAssignLeft
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    rts
.endproc

; This routine sets the type of p^ to what p points to: the subtype of the
; base type of p's type. Like a name's type (see evalName), it has the
; kind, size, param fields and index type of that type's base type (a
; declared type is resolved), and a subtype: the base type's subtype (what
; a pointer points to), or the base type itself. So p^^ looks at what p^
; points to, icode finds what p^ points to in its subtype, and a field of
; p^ finds the record's symbol table (getRecordSymtab). The name is a copy
; of the pointed-to type's name.
.proc evalPointer
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ; Only a pointer or an address can be dereferenced. A left with no
    ; type reported its own error.
    ldz #expr::evalTypeKind
    nop
    lda (ptr1),z
    cmp #TYPE_POINTER
    beq :+
    cmp #TYPE_ADDRESS
    beq :+
    cmp #TYPE_VOID
    lbeq VD
    jmp ER
:   ldz #expr::evalType
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    lbeq VD                     ; The left has no type
    jsr getBaseType
    stq ptr1
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    lbeq ER                     ; It doesn't point to anything (nil)
    stq ptrPointee
    jsr getBaseType
    stq ptrBase

    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldq ptrBase
    stq ptr3
    ldz #type::kind
    nop
    lda (ptr3),z
    nop
    sta (ptr1),z
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
    ldz #type::paramFields
    jsr copyField
    ldz #type::indextype
    jsr copyField
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr3),z
    jsr isQZero
    bne :+
    ldq ptr3
:   stq ptr4
    ldz #type::subtype
    ldx #0
:   lda ptr4,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-

    ldq ptrPointee
    stq ptr3
    ldz #type::name
    neg
    neg
    nop
    lda (ptr3),z
    jsr isQZero
    beq DN
    jsr nameClone
    stq ptr2
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::name
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
DN: rts

ER: lda #errInvalidType
    jsr typeCheckError
VD: ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    lda #TYPE_VOID
    nop
    sta (ptr1),z
    rts

; Copies the pointer at offset Z in the type in ptr3 to the type in ptr1
copyField:
    phz
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr4
    plz
    ldx #0
:   lda ptr4,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    rts
.endproc

; This routine sets the type of an address (@x). Its subtype is a new
; type for what it points to: the kind of the base type, and a record's
; symbol table (getRecordSymtab), which isn't the new type's own
; (TYPE_FLAG_ISCLONED keeps freeType from freeing it).
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

    lda #leftTypeOffset
    jsr calcTypeBlockAddr
    jsr getRecordSymtab
    stq addrSymtab
    lda #leftTypeOffset
    jsr calcTypeBlockAddr
    jsr getBaseType
    stq ptr3
    ldz #type::kind
    nop
    lda (ptr3),z
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
    ora #TYPE_FLAG_ISTEMP | TYPE_FLAG_ISCLONED
    nop
    sta (ptr2),z
    ldz #type::symtab
    ldx #0
:   lda addrSymtab,x
    nop
    sta (ptr2),z
    inz
    inx
    cpx #4
    bne :-

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
    jsr isQZero
    bne :+
    ; Not a name, such as pp^^ or ptrs[2]^. The record's table comes from
    ; the left's type, already checked.
    lda #leftTypeOffset
    jsr calcTypeBlockAddr
    jsr getRecordSymtab
    stq ptr2
    lda #rightTypeOffset
    jsr calcTypeBlockAddr
    stq ptr1
    ldz #type::symtab
    ldx #0
LS: lda ptr2,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne LS
    bra CK
:   stq ptr2
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr2),z
    ldz #rightTypeOffset
    jsr copyToType
    ; Call exprTypeCheck
CK: ldz #exprOffset
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
    ldz #expr::evalTypeKind
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

    ; If the callee resolves to a TYPE declaration rather than a routine,
    ; this is an explicit type-cast expression (TypeName(expr)) and not
    ; a function/procedure call.
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    jsr isExprARoutineCall
    beq L1

    ; Only a type can be cast to. checkFuncProcCall reports anything else.
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

    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr2

    ldz #exprOffset
    jsr loadStackValue
    jsr pushQ                   ; expression (the call/cast node)
    ldq ptr2
    jsr pushQ                   ; return type
    jsr checkTypeCast
    rts

L1: ldz #exprOffset
    jsr loadStackValue
    stq ptr1

    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr2

    ldq ptr1
    jsr pushQ                   ; first argument
    ldq ptr2
    jsr pushQ                   ; return type
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
