;
; checkAbsSqrCall.s
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
argPtrOffset = routineCodeOffset + 1

.export checkAbsSqrCall

.import typeCheckError, loadStackValue, exprTypeCheck, isTypeInteger

.proc checkAbsSqrCall
    ; Push a type onto the stack
    lda #.sizeof(type)
    jsr pushBlock

    ; Needs to have the first parameter
    ldz #argPtrOffset
    jsr loadStackValue
    jsr isQZero
    bne :+
    lda #errWrongNumberOfParams
    jsr typeCheckError
    lda #TYPE_VOID
    jmp DN

    ; It can't have more than one parameter
:   stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    lda #errWrongNumberOfParams
    jsr typeCheckError
    lda #TYPE_VOID
    bra DN

    ; Look at the argument
:   ldq stackPointer
    stq ptr1
    ldz #argPtrOffset
    jsr loadStackValue
    stq ptr2
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr2),z
    jsr pushQ
    jsr pushQZero
    ldq ptr1
    jsr pushQ
    lda #0
    jsr pushA
    jsr exprTypeCheck
    ldq stackPointer
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_REAL
    beq L1
    jsr isTypeInteger
    beq L1
    lda #errInvalidType
    jsr typeCheckError
    lda #TYPE_VOID
    bra DN

    ; If the routine call is Sqr, the return type is a long integer.
L1: ldz #routineCodeOffset
    nop
    lda (stackPointer),z
    cmp #rcSqr
    bne L2
    ldz #type::kind
    nop
    lda (stackPointer),z
    cmp #TYPE_REAL
    beq L2
    lda #TYPE_LONGINT
    jmp DN

L2: ldz #type::kind
    nop
    lda (stackPointer),z

DN: pha
    lda #.sizeof(type)
    jsr popBlock
    jsr popA
    jsr popQ
    pla
    rts
.endproc
