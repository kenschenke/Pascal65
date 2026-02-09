;
; declTypeCheckValue.s
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
valueOffset = typeOffset + .sizeof(type)
declOffset = valueOffset + 4

.export declTypeCheckValue

.import exprTypeCheck, typeCheckError, checkArrayLiteral, checkAssignment, loadStackValue

.bss

varType: .res 4

.code

.proc declTypeCheckValue
    stq ptr1                    ; value expression in ptr1
    jsr pushQ                   ; keep the value on the stack
    lda #.sizeof(type)
    jsr pushBlock               ; type pointer (used in call to exprTypeCheck)

    ldq stackPointer
    stq ptr2                    ; &type

    ldq ptr1
    jsr pushQ                   ; push the value onto the stack again (for exprTypeCheck)
    jsr pushQZero               ; record symtab (n/a)
    ldq ptr2
    jsr pushQ                   ; &type
    lda #0
    jsr pushA                   ; parentIsFuncCall
    jsr exprTypeCheck

    ; Is the decl a variable?
    ldz #declOffset
    jsr loadStackValue
    stq ptr1
    ldz #decl::kind
    nop
    lda (ptr1),z
    cmp #DECL_VARIABLE
    beq :+
    jmp L3

    ; Get the decl's type
:   ldz #decl::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2                    ; type in ptr2
    stq varType
    
    ; Is it an array?
    ldz #type::kind
    nop
    lda (ptr2),z
    cmp #TYPE_ARRAY
    bne L2
    ldz #valueOffset
    jsr loadStackValue
    stq ptr3
    ldz #expr::kind
    nop
    lda (ptr3),z
    cmp #EXPR_ARRAY_LITERAL
    beq :+
    lda #errInvalidConstant
    jsr typeCheckError
    bra L3
:   ldq ptr2
    jsr pushQ                   ; type
    ldq ptr3
    jsr pushQ                   ; value
    jsr checkArrayLiteral
    bra L3

L2: ldz #type::flags
    nop
    lda (stackPointer),z
    and #TYPE_FLAG_ISCONST
    bne :+
    lda #errInvalidConstant
    jsr typeCheckError
    bra L3
:   ldq stackPointer
    stq ptr1
    ldz #valueOffset
    jsr loadStackValue
    stq ptr3
    ldq ptr2
    lda #.sizeof(type)
    jsr pushBlock               ; for throwaway resultType
    ldq stackPointer
    stq ptr4
    ldq varType
    jsr pushQ                   ; variable type (lhalf)
    ldq ptr1
    jsr pushQ                   ; value type (rhalf)
    ldq ptr4
    jsr pushQ                   ; resultType
    ldq ptr3
    jsr pushQ                   ; value expression
    jsr checkAssignment
    lda #.sizeof(type)
    jsr popBlock                ; for throwaway resultType

L3: lda #.sizeof(type)
    jsr popBlock                ; type
    jsr popQ                    ; value
    rts
.endproc
