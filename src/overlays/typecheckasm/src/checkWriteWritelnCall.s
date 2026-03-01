;
; checkWriteWritelnCall.s
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

.export checkWriteWritelnCall

.import typeCheckError, loadStackValue, exprTypeCheck, checkIntegerBaseType
.import checkArraysSameType, isAssignmentCompatible, isTypeInteger

.bss

first: .res 1
exprLeft: .res 4
exprType: .res 4
fileTypeSub: .res .sizeof(type)

.code

.proc checkWriteWritelnCall
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
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ARRAY
    bne :+
    jsr checkArray
    jmp NX
:   cmp #TYPE_RECORD
    bne :+
    jsr checkRecord
    jmp NX
:   cmp #TYPE_REAL
    bne :+
    jsr checkWidthAndPrecision
    jmp NX
:   cmp #TYPE_CHARACTER
    bne :+
    jsr checkWidthAndPrecision
    jmp NX
:   cmp #TYPE_BOOLEAN
    bne :+
    jsr checkWidthAndPrecision
    jmp NX
:   cmp #TYPE_FILE
    bne :+
    jsr checkFile
    jmp NX
:   cmp #TYPE_TEXT
    bne :+
    jsr checkText
    jmp NX
:   cmp #TYPE_STRING_LITERAL
    bne :+
    ; do nothing
    jmp NX
:   cmp #TYPE_STRING_VAR
    bne :+
    ; do nothing
    jmp NX
:   cmp #TYPE_STRING_OBJ
    bne :+
    ; do nothing
    jmp NX
:   jsr isTypeInteger
    bne :+
    jsr checkWidthAndPrecision
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
    cmp #TYPE_RECORD
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
    ldq exprType
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
:   jsr checkWidthAndPrecision
    rts
.endproc

.proc checkRecord
    ldq exprType
    stq ptr1
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #type::symtab
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    ldq fileTypeSub+type::symtab
    stq ptr3
    ldx #0
:   lda ptr2,x
    cmp ptr3,x
    bne :+
    inx
    cpx #4
    bne :-
    rts
:   lda #errIncompatibleTypes
    jsr typeCheckError
    rts
.endproc

.proc checkWidthAndPrecision
    ldq exprLeft
    stq ptr1
    ldz #expr::width
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    jsr checkIntegerBaseType
    ldq exprLeft
    stq ptr1
    ldz #expr::precision
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    jsr checkIntegerBaseType
    rts
.endproc

.proc checkFile
    lda first
    bne :+
    lda #errIncompatibleTypes
    jsr typeCheckError
:   ldz #routineCodeOffset
    nop
    lda (stackPointer),z
    cmp #rcWrite
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
:   ldz #routineCodeOffset
    nop
    lda (stackPointer),z
    cmp #rcWriteStr
    beq :+
    lda #errIncompatibleTypes
    jsr typeCheckError
:   rts
.endproc
