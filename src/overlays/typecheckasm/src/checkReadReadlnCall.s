;
; checkReadReadlnCall.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "symtab.inc"
.include "zeropage.inc"
.include "4510macros.inc"

typeOffset = 0
routineCodeOffset = typeOffset + .sizeof(type)
argOffset = routineCodeOffset + 1

.export checkReadReadlnCall

.import typeCheckError, loadStackValue, exprTypeCheck
.import checkArraysSameType, isAssignmentCompatible

.bss

first: .res 1
exprLeft: .res 4
exprType: .res 4
subscript: .res 1
fileTypeSub: .res .sizeof(type)

.code

.proc checkReadReadlnCall
    ; Push an empty type onto the stack
    lda #.sizeof(type)
    jsr pushBlock

    lda #1
    sta first

    lda #0
    ldx #type::kind
    sta fileTypeSub,x

    ; Loop through the arguments
L1: ldz #argOffset
    jsr loadStackValue
    jsr isQZero
    bne :+
    jmp DN

:   stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq exprLeft

    lda #0
    sta subscript

    ; Evaluate the argument expression type
    ldq stackPointer
    stq ptr1
    ldq exprLeft
    jsr pushQ
    jsr pushQZero
    ldq ptr1
    jsr pushQ
    lda #0
    jsr pushA
    jsr exprTypeCheck
    ldq stackPointer
    jsr getBaseType
    stq exprType
    ldq exprLeft
    stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_SUBSCRIPT
    bne :+
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    stq exprLeft
    lda #1
    sta subscript
    ldz #expr::kind
    nop
    lda (ptr1),z
:   cmp #EXPR_POINTER
    bne :+
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    stq exprLeft
    ldz #expr::kind
    nop
    lda (ptr1),z
:   cmp #EXPR_NAME
    beq :+
    lda #errInvalidVarParm
    jsr typeCheckError
    jmp NX
:   ldz #expr::name
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr4
    jsr scopeLookup
    stq ptr2
    jsr isQZero
    bne :+
    lda #errUndefinedIdentifier
    jsr typeCheckError
    jmp NX
:   ldz #symbol::type
    neg
    neg
    nop
    lda (ptr2),z
    stq exprType
    stq ptr1
    lda subscript
    beq :+
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    stq exprType
:   ldq exprType
    jsr getBaseType
    stq exprType
    stq ptr1
    lda subscript
    beq :+
    ldq exprType
    stq ptr1
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    stq exprType
    stq ptr1
:   ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ARRAY
    bne :+
    jsr checkArray
    jmp NX
:   cmp #TYPE_BOOLEAN
    bne :+
    jsr checkIsConst
    jmp NX
:   cmp #TYPE_CHARACTER
    bne :+
    jsr checkIsConst
    jmp NX
:   cmp #TYPE_BYTE
    bne :+
    jsr checkIsConst
    jmp NX
:   cmp #TYPE_SHORTINT
    bne :+
    jsr checkIsConst
    jmp NX
:   cmp #TYPE_INTEGER
    bne :+
    jsr checkIsConst
    jmp NX
:   cmp #TYPE_WORD
    bne :+
    jsr checkIsConst
    jmp NX
:   cmp #TYPE_CARDINAL
    bne :+
    jsr checkIsConst
    jmp NX
:   cmp #TYPE_LONGINT
    bne :+
    jsr checkIsConst
    jmp NX
:   cmp #TYPE_STRING_VAR
    bne :+
    jsr checkIsConst
    jmp NX
:   cmp #TYPE_REAL
    bne :+
    jsr checkIsConst
    jmp NX
:   cmp #TYPE_FILE
    bne :+
    jsr checkFile
    jmp NX
:   cmp #TYPE_TEXT
    bne :+
    jsr checkText
    jmp NX
:   cmp #TYPE_RECORD
    bne :+
    ; do nothing
    jmp NX
:   lda #errIncompatibleTypes
    jsr typeCheckError

NX: lda first
    bne L2
    ldx #type::kind
    lda fileTypeSub,x
    beq L2
    cmp #TYPE_ARRAY
    beq L2

    jsr pushA
    ldq exprType
    jsr pushQ
    jsr isAssignmentCompatible
    beq L2
    lda #errIncompatibleTypes
    jsr typeCheckError

L2: lda #0
    sta first
    ldz #argOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #argOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    lda #0
    sta first
    jmp L1

DN: lda #.sizeof(type)
    jsr popBlock
    jsr popA
    jsr popQ
    rts
.endproc

.proc checkArray
    ldq exprType
    stq ptr1
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jsr getBaseType
    stq ptr1
    ldx #type::kind
    lda fileTypeSub,x
    beq L1
    ldq ptr1
    jsr pushQ
    lda #<fileTypeSub
    ldx #>fileTypeSub
    ldy #0
    ldz #0
    jsr pushQ
    jsr checkArraysSameType
    rts
L1: ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_CHARACTER
    beq :+
    lda #errIncompatibleTypes
    jsr typeCheckError
:   rts
.endproc

.proc checkIsConst
    ldq exprType
    stq ptr1
    ldz #type::flags
    nop
    lda (ptr1),z
    and #TYPE_FLAG_ISCONST
    beq :+
    lda #errIncompatibleTypes
    jsr typeCheckError
:   rts
.endproc

.proc checkFile
    lda first
    bne :+
    lda #errIncompatibleTypes
    jsr typeCheckError
:   ldz #routineCodeOffset
    nop
    lda (stackPointer),z
    cmp #rcRead
    beq :+
    lda #errIncompatibleTypes
    jsr typeCheckError
:   ldq exprType
    stq ptr1
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    jsr getBaseType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    ldx #type::kind
    sta fileTypeSub,x
:   rts
.endproc

.proc checkText
    lda first
    bne :+
    lda #errIncompatibleTypes
    jsr typeCheckError
:   rts
.endproc
