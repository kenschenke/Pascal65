;
; checkArrayLiteral.s
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

elemsOffset = 0
elemTypeOffset = elemsOffset + 2
exprOffset = elemTypeOffset + 4
valueOffset = exprOffset + 4
arrayTypeOffset = valueOffset + 4

.export checkArrayLiteral

.import loadStackValue, typeCheckError, checkAssignment

.bss

resultTypeDummy: .res .sizeof(type)

.code

.proc checkArrayLiteral
    jsr pushQZero               ; put null on the stack for the current literal expression
    jsr pushQZero               ; put null on the stack for the element type
    lda #0
    tax
    jsr pushAX                  ; elems

    ; Look the element type and store it on the stack
    ldz #arrayTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #elemTypeOffset
    jsr storeStackValue

    ; Start with the first literal value
    ldz #valueOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #exprOffset
    jsr storeStackValue

L1: ldz #exprOffset
    jsr loadStackValue
    jsr isQZero
    bne :+
    jmp L5

    ; Is the element type another array?
:   ldz #elemTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ARRAY
    bne L3
    
    ; If the array elements are arrays then
    ; the literal must be an array literal
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_ARRAY_LITERAL
    bne L2
    lda #errInvalidConstant
    jsr typeCheckError

    ; Check the element array literal
L2: ldz #elemTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #exprOffset
    jsr loadStackValue
    stq ptr2
    ldq ptr1
    jsr pushQ
    ldq ptr2
    jsr pushQ
    jsr checkArrayLiteral
    bra L4

    ; Check the literal's value to make sure it's compatible with the element type
L3: ldz #elemTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #exprOffset
    jsr loadStackValue
    stq ptr2
    ldz #expr::evalType
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    ldz #exprOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr3
    ldq ptr1
    jsr pushQ
    ldq ptr2
    jsr pushQ
    lda #<resultTypeDummy
    ldx #>resultTypeDummy
    ldy #0
    ldz #0
    jsr pushQ
    ldq ptr3
    jsr pushQ
    jsr checkAssignment

    ; Increment elems
L4: ldz #elemsOffset
    nop
    lda (stackPointer),z
    clc
    adc #1
    nop
    sta (stackPointer),z
    inz
    nop
    lda (stackPointer),z
    adc #0
    nop
    sta (stackPointer),z

    ; Move to the next expression
    ldz #exprOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #exprOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    jmp L1

    ; Make sure the array literal does not have too many elements
L5: ldz #arrayTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::indextype
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #type::min
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    ; Put the min in intOp2
    ldz #expr::value
    nop
    lda (ptr2),z
    sta intOp2
    inz
    nop
    lda (ptr2),z
    sta intOp2+1
    ; Put the max in intOp1
    ldz #type::max
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    ldz #expr::value
    nop
    lda (ptr2),z
    sta intOp1
    inz
    nop
    lda (ptr2),z
    sta intOp1+1
    ; max - min
    jsr subInt16
    ; +1
    lda #1
    sta intOp2
    lda #0
    sta intOp2+1
    jsr addInt16
    ; Copy intOp1 to intOp2
    lda intOp1
    sta intOp2
    lda intOp1+1
    sta intOp2+1
    ; Put elems in intOp1
    ldz #elemsOffset
    nop
    lda (stackPointer),z
    sta intOp1
    inz
    nop
    lda (stackPointer),z
    sta intOp1+1
    jsr gtInt16
    beq :+
    lda #errIndexOutOfRange
    jsr typeCheckError

:   jsr popAX
    jsr popQ
    jsr popQ
    jsr popQ
    jsr popQ
    rts
.endproc

; Stores the value in ptr1 to the offset on the stack in Z.
.proc storeStackValue
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    rts
.endproc
