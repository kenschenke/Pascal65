;
; icodeExpr.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"
.include "icode.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"
.include "cbm_kernal.inc"

symPtrOffset = 0
isDeRefOffset = symPtrOffset + 4
isReadOffset = isDeRefOffset + 1
exprOffset = isReadOffset + 1

.export icodeExpr, icodeExprRead

.import loadStackValue, getExprTypeKind, icodeIntOrRealMath
.import icodeOper1Short, icodeOper2Short, icodeOper3Short, icodeWriteInstruction
.import icodeSubroutineCall, icodeCompExpr, getExprType, icodeStringValue
.import lblRoutineEnter, icodeFormatLabel, icodeOper1Label, icodeVar

.import icodeBoolValue, icodeShortValue, icodeWordValue, icodeLongValue, icodeRealValue
.import icodeCharValue, icodeOper1Word

.bss

rightType: .res .sizeof(type)
symPtr: .res 4
isByRef: .res 1

.code

; Parameters on stack, bottom to top:
;    expression ptr
;    isRead
.proc icodeExpr
    lda #1
    jsr pushA
    jmp icodeExprPvt
.endproc

; Expression in Q
.proc icodeExprRead
    jsr pushQ
    lda #1
    jsr pushA
    lda #1
    jsr pushA
    ; Fall through to icodeExprPvt
.endproc

; Parameters on stack, bottom to top:
;    expression ptr
;    isRead
;    isDeRef
.proc icodeExprPvt
    jsr pushQZero               ; symPtr

    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_ADD
    bne :+
    jsr exprAdd
    jmp DN
:   cmp #EXPR_SUB
    bne :+
    jsr exprSubMul
    jmp DN
:   cmp #EXPR_MUL
    bne :+
    jsr exprSubMul
    jmp DN
:   cmp #EXPR_CALL
    bne :+
    ldq ptr1
    jsr icodeSubroutineCall
    jmp DN
:   cmp #EXPR_DIVINT
    bne :+
    lda #IC_DVI
    jsr trinaryMathCall
    jmp DN
:   cmp #EXPR_BITWISE_AND
    bne :+
    lda #IC_BWA
    jsr trinaryMathCall
    jmp DN
:   cmp #EXPR_BITWISE_OR
    bne :+
    lda #IC_BWO
    jsr trinaryMathCall
    jmp DN
:   cmp #EXPR_BITWISE_LSHIFT
    bne :+
    lda #IC_BSL
    jsr trinaryMathCall
    jmp DN
:   cmp #EXPR_BITWISE_RSHIFT
    bne :+
    lda #IC_BSR
    jsr trinaryMathCall
    jmp DN
:   cmp #EXPR_BITWISE_XOR
    bne :+
    lda #IC_BWX
    jsr trinaryMathCall
    jmp DN
:   cmp #EXPR_EQ
    bne :+
    ldq ptr1
    jsr icodeCompExpr
    jmp DN
:   cmp #EXPR_LT
    bne :+
    ldq ptr1
    jsr icodeCompExpr
    jmp DN
:   cmp #EXPR_LTE
    bne :+
    ldq ptr1
    jsr icodeCompExpr
    jmp DN
:   cmp #EXPR_GT
    bne :+
    ldq ptr1
    jsr icodeCompExpr
    jmp DN
:   cmp #EXPR_GTE
    bne :+
    ldq ptr1
    jsr icodeCompExpr
    jmp DN
:   cmp #EXPR_NE
    bne :+
    ldq ptr1
    jsr icodeCompExpr
    jmp DN
:   cmp #EXPR_DIV
    bne :+
    lda #IC_DIV
    jsr exprDivMod
    jmp DN
:   cmp #EXPR_MOD
    bne :+
    lda #IC_MOD
    jsr exprDivMod
    jmp DN
:   cmp #EXPR_AND
    bne :+
    lda #IC_AND
    jsr exprAndOr
    jmp DN
:   cmp #EXPR_OR
    bne :+
    lda #IC_ORA
    jsr exprAndOr
    jmp DN
:   cmp #EXPR_NOT
    bne :+
    jsr exprNot
    jmp DN
:   cmp #EXPR_ASSIGN
    bne :+
    jsr exprAssign
    jmp DN
:   cmp #EXPR_POINTER
    bne :+
    jsr exprPointer
    jmp DN
:   cmp #EXPR_ADDRESS_OF
    bne :+
    jsr exprAddressOf
    jmp DN
:   cmp #EXPR_BOOLEAN_LITERAL
    bne :+
    ldq ptr1
    jsr icodeBoolValue
    jmp DN
:   cmp #EXPR_BYTE_LITERAL
    bne :+
    ldq ptr1
    jsr icodeShortValue
    lda #TYPE_BYTE
    jmp DN
:   cmp #EXPR_WORD_LITERAL
    bne :+
    ldq ptr1
    jsr icodeWordValue
    jmp DN
:   cmp #EXPR_DWORD_LITERAL
    bne :+
    ldq ptr1
    jsr icodeLongValue
    jmp DN
:   cmp #EXPR_REAL_LITERAL
    bne :+
    ldq ptr1
    jsr icodeRealValue
    lda #TYPE_REAL
    jmp DN
:   cmp #EXPR_CHARACTER_LITERAL
    bne :+
    ldq ptr1
    jsr icodeCharValue
    jmp DN
:   cmp #EXPR_NAME
    bne :+
    jsr exprName
    jmp DN
:   cmp #EXPR_SUBSCRIPT
    bne :+
    jsr exprSubscript
    jmp DN
:   cmp #EXPR_FIELD
    bne :+
    jsr exprField
    jmp DN
:   cmp #EXPR_STRING_LITERAL
    bne DN
    ldz #expr::value
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeStringValue
    lda #TYPE_STRING_LITERAL

DN: pha
    jsr popQ
    jsr popA
    jsr popA
    jsr popQ
    pla
    rts
.endproc

.proc exprAdd
    ; Check if the left and right operands are both concatenation operands:
    ;    * character
    ;    * string
    ;    * array of characters
    ldz #expr::left
    jsr getChildExpr
    jsr isConcatOperand
    bne L1
    ldz #expr::right
    jsr getChildExpr
    jsr isConcatOperand
    bne L1

    ; String concatenation
    ldz #expr::left
    jsr getChildExpr
    jsr icodeExprRead
    ldz #expr::right
    jsr getChildExpr
    jsr icodeExprRead
    ldz #expr::left
    jsr getChildExpr
    jsr getExprTypeKind
    jsr icodeOper1Short
    ldz #expr::right
    jsr getChildExpr
    jsr getExprTypeKind
    jsr icodeOper2Short
    lda #IC_CCT
    jsr icodeWriteInstruction
    lda #TYPE_STRING_OBJ
    rts

L1: ldz #exprOffset
    jsr loadStackValue
    jsr icodeIntOrRealMath
    rts
.endproc

.proc exprAddressOf
    ldz #expr::left
    jsr getChildExpr
    jsr pushQ
    lda #0
    jsr pushA
    lda #0
    jsr pushA
    jsr icodeExprPvt

    ldz #expr::left
    jsr getChildExpr
    jsr getExprType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_PROCEDURE
    beq RT
    cmp #TYPE_FUNCTION
    beq RT

    lda #TYPE_ADDRESS
    rts

RT: lda #TYPE_ROUTINE_ADDRESS
    rts
.endproc

.proc exprAndOr
    pha                 ; Save the operation type

    ldz #expr::left
    jsr getChildExpr
    jsr icodeExprRead

    ldz #expr::right
    jsr getChildExpr
    jsr icodeExprRead

    pla
    jsr icodeWriteInstruction
    rts
.endproc

.proc exprAssign
    ; The left expression will always be an address in ptr1.
    ; The assignment will be carried out using the store* routines.

    ; The right side will always leave the assigned value on the stack.

    ldz #expr::right
    jsr getChildExpr
    jsr icodeExprRead

    ldz #expr::left
    jsr getChildExpr
    jsr pushQ
    lda #0
    jsr pushA
    lda #0
    jsr pushA
    jsr icodeExprPvt

    ldz #expr::left
    jsr getChildExpr
    jsr getExprType
    jsr getBaseType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    jsr icodeOper1Short

    ldz #expr::right
    jsr getChildExpr
    jsr getExprType
    jsr getBaseType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    jsr icodeOper2Short

    lda #IC_SET
    jsr icodeWriteInstruction

    lda #TYPE_VOID
    rts
.endproc

.proc exprDivMod
    pha                 ; Save the operation type

    ldz #expr::left
    jsr getChildExpr
    jsr icodeExprRead

    ldz #expr::right
    jsr getChildExpr
    jsr icodeExprRead

    ldz #expr::left
    jsr getChildExpr
    jsr getExprTypeKind
    jsr icodeOper1Short

    ldz #expr::right
    jsr getChildExpr
    jsr getExprTypeKind
    jsr icodeOper2Short
    pla
    jsr icodeWriteInstruction

    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_DIV
    bne :+
    lda #TYPE_REAL
    rts
:   ldz #expr::left
    jsr getChildExpr
    jsr getExprTypeKind
    rts
.endproc

.proc exprField
    ; First, look up the left expression. If it's also a subscript or field,
    ; it needs to be processed first.
    ldz #expr::left
    jsr getChildExpr
    jsr getExprType
    stq ptr1
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    stq ptr1
:   ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_DECLARED
    bne :+
    ldz #type::name
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr4
    jsr scopeLookup
    stq ptr1
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
:   ldz #type::symtab
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr3

    ldz #expr::right
    jsr getChildExpr
    stq ptr2
    ldz #expr::name
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr4

    ldq ptr3
    stq ptr1

    jsr symtabLookup
    stq ptr1

    ldz #symPtrOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-

    ldz #expr::left
    jsr getChildExpr
    stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_POINTER
    bne :+
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
:   ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_NAME
    beq :+
    ldq ptr1
    jsr pushQ
    lda #0
    jsr pushA
    jsr icodeExpr
    bra L1
:   ldq ptr1
    jsr icodeExprRead

L1: ldz #symPtrOffset
    jsr loadStackValue
    stq ptr1

    ldz #symbol::offset
    nop
    lda (ptr1),z
    beq :+
    jsr icodeOper1Short
    lda #IC_PSH
    jsr icodeWriteInstruction
    lda #TYPE_WORD
    jsr icodeOper1Short
    lda #TYPE_WORD
    jsr icodeOper2Short
    lda #TYPE_WORD
    jsr icodeOper3Short
    lda #IC_ADD
    jsr icodeWriteInstruction
:   ldz #expr::right
    jsr getChildExpr
    jsr getExprType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    pha
    ldz #isReadOffset
    nop
    lda (stackPointer),z
    beq :+
    pla
    pha
    jsr icodeOper1Short
    lda #IC_MEM
    jsr icodeWriteInstruction
:   pla
    rts
.endproc

.proc exprName
    lda #0
    tax
:   sta rightType,x
    inx
    cpx #.sizeof(type)
    bne :-

    ldz #expr::name
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr4
    jsr scopeLookupParent
    jsr isQZero
    beq L1
    stq ptr1
    stq symPtr
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #0
    ldx #0
:   nop
    lda (ptr1),z
    sta rightType,x
    inz
    inx
    cpx #.sizeof(type)
    bne :-
L1: lda rightType+type::flags
    bne L2
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::name
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr4
    jsr scopeLookup
    jsr isQZero
    beq L2
    stq ptr1
    stq symPtr
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #0
    ldx #0
:   nop
    lda (ptr1),z
    sta rightType,x
    inx
    inz
    cpx #.sizeof(type)
    bne :-
L2: lda rightType
    cmp #TYPE_DECLARED
    bne L3
    lda rightType+type::flags
    pha
    ldq rightType+type::name
    stq ptr4
    jsr scopeLookup
    stq ptr1
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #0
    ldx #0
:   nop
    lda (ptr1),z
    sta rightType,x
    inx
    inz
    cpx #.sizeof(type)
    bne :-
    pla
    sta rightType+type::flags

L3: lda rightType+type::flags
    and #TYPE_FLAG_ISRETVAL
    beq :+
    lda #IC_PSH
    jsr CHROUT
    lda #IC_RET
    jsr CHROUT
    jmp DN
:   lda rightType
    cmp #TYPE_ENUMERATION_VALUE
    bne :+
    ldq symPtr
    stq ptr1
    ldz #symbol::decl
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #decl::value
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #expr::value
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeOper1Word
    lda #IC_PSH
    jsr icodeWriteInstruction
    jmp DN
:   cmp #TYPE_FUNCTION
    beq L4
    cmp #TYPE_PROCEDURE
    beq L4
    jmp L5

    ; Function or procedure
L4: ldq symPtr
    stq ptr1
    ldz #symbol::decl
    neg
    neg
    nop
    lda (ptr1),z
    stq intOp32
    lda #<lblRoutineEnter
    ldx #>lblRoutineEnter
    jsr icodeFormatLabel
    jsr icodeOper1Label
    ldq symPtr
    stq ptr1
    ldz #symbol::level
    nop
    lda (ptr1),z
    jsr icodeOper2Short
    lda #0
    jsr icodeOper3Short
    lda #IC_PRP
    jsr icodeWriteInstruction
    jmp DN

L5: ldq rightType+type::subtype
    jsr isQZero
    beq :+
    lda rightType
    cmp #TYPE_POINTER
    bne :+
    ldq rightType+type::subtype
    stq ptr1
    ldz #type::flags
    nop
    lda (ptr1),z
    bra L6
:   lda rightType+type::flags

    ; Flags in A
L6: and #TYPE_FLAG_ISBYREF
    sta isByRef

    ldz #isReadOffset
    nop
    lda (stackPointer),z
    beq NR

    lda #IC_VVR
    ldx isByRef
    bne IV
    lda #IC_VDR
    bra IV

    ; Not isRead
NR: lda #IC_VVW
    ldx isByRef
    bne IV
    lda #IC_VDW

IV: jsr pushA               ; operation
    lda rightType
    jsr pushA               ; kind
    ldq symPtr
    stq ptr1
    ldz #symbol::level
    nop
    lda (ptr1),z
    jsr pushA               ; level
    ldz #symbol::offset
    nop
    lda (ptr1),z
    jsr pushA               ; offset
    jsr icodeVar

    lda isByRef
    beq DN
    ldz #isReadOffset
    nop
    lda (stackPointer),z
    beq DN

    lda rightType
    jsr icodeOper1Short
    lda #IC_MEM
    jsr icodeWriteInstruction

DN: lda rightType
    rts
.endproc

.proc exprNot
    ldz #expr::left
    jsr getChildExpr
    jsr icodeExprRead

    ldz #expr::left
    jsr getChildExpr
    jsr getExprTypeKind
    pha
    cmp #TYPE_BOOLEAN
    bne :+
    lda #IC_NOT
    jsr icodeWriteInstruction
    pla
    rts
:   pla
    pha
    jsr icodeOper1Short
    lda #IC_BWC
    jsr icodeWriteInstruction
    pla
    rts
.endproc

.proc exprPointer
    ldz #expr::left
    jsr getChildExpr
    jsr pushQ
    lda #1
    jsr pushA
    lda #0
    jsr pushA
    jsr icodeExprPvt

    ldz #expr::left
    jsr getChildExpr
    jsr getExprType
    stq ptr1
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jsr getBaseType
    stq ptr1
    ldz #isReadOffset
    nop
    lda (stackPointer),z
    beq L2

    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ARRAY
    beq L1
    cmp #TYPE_RECORD
    beq L1
    cmp #TYPE_STRING_OBJ
    beq L1
    cmp #TYPE_STRING_VAR
    bne L2

L1: jsr icodeOper1Short
    lda #IC_MEM
    jsr icodeWriteInstruction
    rts

L2: ldz #isDeRefOffset
    nop
    lda (stackPointer),z
    beq L3
    ldz #type::kind
    nop
    lda (ptr1),z
    pha
    jsr icodeOper1Short
    lda #IC_MEM
    jsr icodeWriteInstruction
    pla

L3: rts
.endproc

.proc exprSubMul
    ldq ptr1
    jsr icodeIntOrRealMath
    rts
.endproc

.proc exprSubscript
    ; First, look up the left expression. If it's also a subscript or a field,
    ; it needs to be processed first.
    ldz #expr::left
    jsr getChildExpr
    stq ptr1
    ldz #expr::evalType
    neg
    neg
    nop
    lda (ptr1),z
    jsr getBaseType
    stq ptr2
    ldz #type::kind
    nop
    lda (ptr2),z
    cmp #TYPE_STRING_VAR
    bne L1
    ldz #isReadOffset
    nop
    lda (stackPointer),z
    beq :+
    ldz #expr::right
    jsr getChildExpr
    jsr icodeExprRead
    ldz #expr::left
    jsr getChildExpr
    jsr icodeExprRead
    lda #IC_SSR
    jsr icodeWriteInstruction
    rts
:   ldz #expr::left
    jsr getChildExpr
    jsr icodeExprRead
    ldz #expr::right
    jsr getChildExpr
    jsr icodeExprRead
    lda #IC_SSW
    jsr icodeWriteInstruction
    rts

L1: ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_NAME
    beq :+
    ; Look up the array index
    ldz #expr::left
    jsr getChildExpr
    ; If the left is a record field or a subscript, isRead should be 0.
    ; Otherwise, it should be 1.
    stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_FIELD
    beq :+
    cmp #EXPR_SUBSCRIPT
    bne LF
:   ldq ptr1
    jsr pushQ
    lda #0
    jsr pushA
    jsr icodeExpr
    bra LR
LF: ldq ptr1
    jsr icodeExprRead
    ; Put the address of the array variable into ptr1
LR: ldz #expr::right
    jsr getChildExpr
    jsr icodeExprRead
    bra L2

:   ldz #isDeRefOffset
    nop
    lda (stackPointer),z
    pha
    ldz #expr::left
    jsr getChildExpr
    jsr pushQ
    lda #0
    jsr pushA
    pla
    jsr pushA
    jsr icodeExprPvt
    ldz #isReadOffset
    nop
    lda (stackPointer),z
    bne :+
    ldz #expr::left
    jsr getChildExpr
    stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_POINTER
    bne :+
    lda #TYPE_ADDRESS
    jsr icodeOper1Short
    lda #IC_MEM
    jsr icodeWriteInstruction
:   ldz #expr::right
    jsr getChildExpr
    jsr icodeExprRead

L2: ldz #expr::right
    jsr getChildExpr
    stq ptr1
    ldz #expr::evalType
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    ldz #type::kind
    nop
    lda (ptr2),z
    jsr icodeOper1Short
    lda #IC_AIX
    jsr icodeWriteInstruction

    ; if (isRead)
    ldz #isReadOffset
    nop
    lda (stackPointer),z
    bne :+
    rts

:   ldz #expr::left
    jsr getChildExpr
    jsr getExprType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_DECLARED
    bne :+
    ldq ptr1
    jsr getBaseType
    stq ptr1
:   ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
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
    stq ptr1
:   ldz #type::kind
    nop
    lda (ptr1),z
    pha
    jsr icodeOper1Short
    lda #IC_MEM
    jsr icodeWriteInstruction
    pla
    rts
.endproc

; This little helper routine gets either the left or right
; child expression. expr::left or expr::right is passed in Z.
.proc getChildExpr
    phz
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    plz
    neg
    neg
    nop
    lda (ptr1),z
    rts
.endproc

; This routine gets the type kind of the evaluation type
; The type kind is returned in A.
.proc getEvalTypeKind
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::evalType
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    rts
.endproc

.proc trinaryMathCall
    pha             ; Save the math operation

    ldz #expr::left
    jsr getChildExpr
    jsr icodeExprRead

    ldz #expr::right
    jsr getChildExpr
    jsr icodeExprRead

    ldz #expr::left
    jsr getChildExpr
    jsr getExprTypeKind
    jsr icodeOper1Short

    ldz #expr::right
    jsr getChildExpr
    jsr getExprTypeKind
    jsr icodeOper2Short

    jsr getEvalTypeKind
    jsr icodeOper3Short

    pla
    jsr icodeWriteInstruction
    jsr getEvalTypeKind
    rts
.endproc
