;
; checkArrayRoutineCall.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Type checking for the array routines: SetLength, Length, Low, and High.

.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

typeOffset = 0
argOffset = typeOffset + .sizeof(type)

.export checkSetLengthCall, checkArrayFuncCall, isDynamicArray

.import typeCheckError, loadStackValue, exprTypeCheck, isTypeInteger

.code

; This routine checks a call to Low, High, or Length (with an array).
; There must be one argument and it must be an array, static or dynamic.
; The first argument (EXPR_ARG) is passed on the runtime stack.
; The caller sets the return type.
.proc checkArrayFuncCall
    lda #.sizeof(type)
    jsr pushBlock
    jsr zeroArgType

    ; There must be exactly one argument
    ldz #argOffset
    jsr loadStackValue
    jsr isQZero
    beq WN
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
WN: lda #errWrongNumberOfParams
    jsr typeCheckError
    bra DN

    ; Evaluate the argument
:   ldz #argOffset
    jsr checkArgType
    ldq stackPointer
    jsr getBaseType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ARRAY
    beq DN
    lda #errInvalidType
    jsr typeCheckError

DN: jsr freeArgTypeName
    lda #.sizeof(type)
    jsr popBlock
    jsr popQ
    rts
.endproc

; This routine checks a call to SetLength. There must be two arguments.
; The first is a dynamic array variable and the second is an integer.
; The first argument (EXPR_ARG) is passed on the runtime stack.
.proc checkSetLengthCall
    lda #.sizeof(type)
    jsr pushBlock
    jsr zeroArgType

    ; There must be exactly two arguments
    ldz #argOffset
    jsr loadStackValue
    jsr isQZero
    beq WN
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq WN
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
WN: lda #errWrongNumberOfParams
    jsr typeCheckError
    jmp DN

    ; The first argument must be a dynamic array variable, named (not a
    ; pointer dereference), and not a constant. The intermediate code
    ; names the array's declaration block from the variable's symbol.
:   ldz #argOffset
    jsr checkArgType
    ldz #type::flags
    nop
    lda (stackPointer),z
    and #TYPE_FLAG_ISCONST
    bne BA
    ldz #argOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_NAME
    bne BA
    ldq stackPointer
    jsr isDynamicArray
    beq L1
BA: lda #errInvalidType
    jsr typeCheckError

    ; The second argument must be an integer
L1: jsr freeArgTypeName
    lda #0
    taz
:   nop
    sta (stackPointer),z
    inz
    cpz #.sizeof(type)
    bne :-
    ldz #argOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    jsr checkExprArg
    ldq stackPointer
    jsr getBaseType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    jsr isTypeInteger
    beq DN
    lda #errInvalidType
    jsr typeCheckError

DN: jsr freeArgTypeName
    lda #.sizeof(type)
    jsr popBlock
    jsr popQ
    rts
.endproc

; This routine evaluates the type of the argument (EXPR_ARG) whose pointer
; is on the runtime stack at the offset in Z. The type is stored in the
; type block at the top of the runtime stack.
.proc checkArgType
    jsr loadStackValue
    stq ptr1
    ; fall through
.endproc

; This routine evaluates the type of the argument (EXPR_ARG) in ptr1.
; The type is stored in the type block at the top of the runtime stack.
.proc checkExprArg
    ldq stackPointer
    stq ptr2
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    jsr pushQZero
    ldq ptr2
    jsr pushQ
    lda #0
    jsr pushA
    jmp exprTypeCheck
.endproc

; Evaluating an argument can put a copy of a type name in the type block
; (a dereferenced pointer to a named type does). This routine frees it.
.proc freeArgTypeName
    ldz #type::name
    neg
    neg
    nop
    lda (stackPointer),z
    jsr isQZero
    beq DN
    jsr heapFree
    jmp zeroArgType
DN: rts
.endproc

; This routine zeroes the type block at the top of the runtime stack.
.proc zeroArgType
    lda #0
    taz
:   nop
    sta (stackPointer),z
    inz
    cpz #.sizeof(type)
    bne :-
    rts
.endproc

; This routine checks if the type in Q is a dynamic array.
; The Z flag is set if it is.
.proc isDynamicArray
    jsr getBaseType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ARRAY
    bne NO
    ldz #type::flags
    nop
    lda (ptr1),z
    and #TYPE_FLAG_ISDYNAMIC
    beq NO
    lda #0
    rts
NO: lda #1
    rts
.endproc
