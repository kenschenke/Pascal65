;
; checkDecIncCall.s
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
argOffset = typeOffset + .sizeof(type)

.export checkDecIncCall

.import typeCheckError, loadStackValue, exprTypeCheck, isTypeInteger
.import followPtr1, loadQPtr1, typeErrInvalidType, typeErrParamCount

.proc checkDecIncCall
    ; Push an empty type onto the stack
    lda #.sizeof(type)
    jsr pushBlock

    ; Needs to have the first parameter
    ldz #argOffset
    jsr loadStackValue
    jsr isQZero
    bne :+
    jsr typeErrParamCount
    jmp DN

    ; Look at the first argument.
    ; It must be an integer, character, pointer, or enumeration.
:   ldz #argOffset
    jsr loadStackValue
    stq ptr1
    ldq stackPointer
    stq ptr2
    ldz #expr::left
    jsr loadQPtr1
    jsr pushQ
    jsr pushQZero
    ldq ptr2
    jsr pushQ
    lda #0
    jsr pushA
    jsr exprTypeCheck
    ldq stackPointer
    jsr getBaseType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_CHARACTER
    beq L1
    cmp #TYPE_ENUMERATION
    beq L1
    cmp #TYPE_POINTER
    beq L1
    jsr isTypeInteger
    beq L1
    jsr typeErrInvalidType
    jmp DN

    ; The argument must be a variable and not constant
L1: ldz #type::flags
    nop
    lda (stackPointer),z
    and #TYPE_FLAG_ISCONST
    beq L2
    jsr typeErrInvalidType
    jmp DN

    ; If there is a second argument, it must be an integer.
L2: ldz #argOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::right
    jsr loadQPtr1
    jsr isQZero
    beq DN
    stq ptr1

    ; Get the type of the second argument's expression
    ldz #expr::left
    jsr followPtr1
    ldq stackPointer
    stq ptr2
    ldq ptr1
    jsr pushQ
    jsr pushQZero
    ldq ptr2
    jsr pushQ
    lda #0
    jsr pushA
    jsr exprTypeCheck
    ldz #type::kind
    nop
    lda (stackPointer),z
    jsr isTypeInteger
    beq L3
    jsr typeErrInvalidType
    jmp DN

    ; Check for a third argument (can't have one).
L3: ldz #argOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::right
    jsr followPtr1
    ldz #expr::right
    jsr loadQPtr1
    jsr isQZero
    beq DN
    jsr typeErrParamCount

DN: lda #.sizeof(type)
    jsr popBlock
    jsr popQ
    rts
.endproc
