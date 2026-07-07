;
; icodeArrayInit.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; icodeArrayInit

.include "ast.inc"
.include "icode.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

; Local variables
initBufOffset = 0
elemTypeOffset = initBufOffset + 4
numElementsOffset = elemTypeOffset + 4
highBoundOffset = numElementsOffset + 2
lowBoundOffset = highBoundOffset + 2
; Passed to icodeArrayInit on stack
declPtrOffset = lowBoundOffset + 2
exprInitOffset = declPtrOffset + 4
typePtrOffset = exprInitOffset + 4
labelOffset = typePtrOffset + 4

.export icodeArrayInit

.import icodeSaveData, heapOffset, loadStackValue, icodeSaveData, calcNamePtr
.import addStringArrayLiterals, addScalarArrayLiterals, addEmbeddedArrayOrRecord

.bss

declBuf: .res 2
buffer: .res 3

.code

; Parameters passed on stack, bottom to top
;    label
;    type pointer
;    exprInit pointer
;    decl pointer
.proc icodeArrayInit
    lda #0
    tax
    jsr pushAX      ; lowBound

    lda #0
    tax
    jsr pushAX      ; highBound

    lda #0
    tax
    jsr pushAX      ; numElements

    jsr pushQZero   ; elemType

    jsr allocMemBuf
    jsr pushQ       ; initBuf

    ; Get the upper and low bounds
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::indextype
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    ldz #type::min
    neg
    neg
    nop
    lda (ptr2),z
    jsr getArrayLimit
    ldz #lowBoundOffset
    nop
    sta (stackPointer),z
    inz
    txa
    nop
    sta (stackPointer),z
    ldz #type::max
    neg
    neg
    nop
    lda (ptr2),z
    jsr getArrayLimit
    ldz #highBoundOffset
    nop
    sta (stackPointer),z
    inz
    txa
    nop
    sta (stackPointer),z

    jsr calcNumElements

    ; Look up the element type
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1

    ; Check if the element is a record
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_DECLARED
    bne :+
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    stq ptr1

    ; Save the element type pointer
:   ldz #elemTypeOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-

    ; Start writing out the array declaration block

    ; heap offset
    ldz #initBufOffset
    jsr loadStackValue
    stq ptr1
    lda #<heapOffset
    sta ptr2
    lda #>heapOffset
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #2
    ldx #0
    jsr writeToMemBuf

    ; lower bound
    lda #lowBoundOffset
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq stackPointer
    clc
    adcq intOp32
    stq ptr2
    lda #2
    ldx #0
    jsr writeToMemBuf

    ; upper bound
    lda #highBoundOffset
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq stackPointer
    clc
    adcq intOp32
    stq ptr2
    lda #2
    ldx #0
    jsr writeToMemBuf

    ; element size
    lda #type::size
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldz #elemTypeOffset
    jsr loadStackValue
    clc
    adcq intOp32
    stq ptr2
    lda #2
    ldx #0
    jsr writeToMemBuf

    ldz #elemTypeOffset
    jsr loadStackValue
    jsr getBaseType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ARRAY
    bne :+
    lda #ARRAYDECL_ARRAY
    jsr writeArrayElemType
    jsr writeArrayOrRecordInitLabel
    bra L1
:   cmp #TYPE_RECORD
    bne :+
    lda #ARRAYDECL_RECORD
    jsr writeArrayElemType
    jsr writeArrayOrRecordInitLabel
    bra L1
:   cmp #TYPE_STRING_VAR
    bne :+
    jsr writeStringElems
    bra L1
:   cmp #TYPE_FILE
    bne :+
    lda #ARRAYDECL_FILE
    jsr writeArrayElemType
    jsr finishOutArrayBlock
    bra L1
:   cmp #TYPE_TEXT
    bne :+
    lda #ARRAYDECL_FILE
    jsr writeArrayElemType
    jsr finishOutArrayBlock
    bra L1
:   cmp #TYPE_REAL
    bne :+
    jsr writeRealElems
    bra L1
:   jsr writeScalarElems

L1: ldz #initBufOffset
    jsr loadStackValue
    stq ptr1
    ldz #labelOffset
    jsr loadStackValue
    stq ptr2
    lda #ARRAYDECL_ARRAY
    jsr pushA
    ldq ptr1
    jsr pushQ
    ldq ptr2
    jsr pushQ
    jsr icodeSaveData

    ; Move past array header
    lda heapOffset
    clc
    adc #6
    sta heapOffset
    lda heapOffset+1
    adc #0
    sta heapOffset+1

    ldz #elemTypeOffset
    jsr loadStackValue
    jsr getBaseType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ARRAY
    bne :+
    jsr embeddedArrayOrRecord
    bra L2
:   cmp #TYPE_RECORD
    bne :+
    jsr embeddedArrayOrRecord
    bra L2

    ; Move heapOffset by the size of the array elements
:   ldz #type::size
    nop
    lda (ptr1),z
    sta intOp1
    inz
    nop
    lda (ptr1),z
    sta intOp1+1
    ldz #numElementsOffset
    nop
    lda (stackPointer),z
    sta intOp2
    inz
    nop
    lda (stackPointer),z
    sta intOp2+1
    jsr multInt16
    lda heapOffset
    clc
    adc intOp1
    sta heapOffset
    lda heapOffset+1
    adc intOp1+1
    sta heapOffset+1

    ; Pop local variables
L2: jsr popQ        ; initBuf
    jsr popQ        ; elemType
    jsr popAX       ; numElements
    jsr popAX       ; highBound
    jsr popAX       ; lowBound
    ; Pop parameters
    jsr popQ        ; typePtr
    jsr popQ        ; exprInit
    jsr popQ        ; declPtr
    jsr popQ        ; labelPtr

    rts
.endproc

.proc embeddedArrayOrRecord
    ldz #lowBoundOffset
    nop
    lda (stackPointer),z
    sta intOp1
    inz
    nop
    lda (stackPointer),z
    sta intOp1+1

    ldz #highBoundOffset
    nop
    lda (stackPointer),z
    sta intOp2
    inz
    nop
    lda (stackPointer),z
    sta intOp2+1

    ldz #elemTypeOffset
    jsr loadStackValue
    jsr getBaseType
    stq ptr1

    ldz #declPtrOffset
    jsr loadStackValue
    stq ptr2

    ldz #exprInitOffset
    jsr loadStackValue
    stq ptr3
    
    ldz #labelOffset
    jsr loadStackValue
    jsr pushQ               ; label
    lda intOp1
    ldx intOp1+1
    jsr pushAX              ; lowBound
    lda intOp2
    ldx intOp2+1
    jsr pushAX              ; highBound
    ldq ptr1
    jsr pushQ               ; elemType
    ldq ptr2
    jsr pushQ               ; declPtr
    ldq ptr3
    jsr pushQ               ; exprInit
    jsr addEmbeddedArrayOrRecord
    rts
.endproc

; ARRAYDECL type passed in A
.proc writeArrayElemType
    sta declBuf
    lda #<declBuf
    sta ptr2
    lda #>declBuf
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    ldz #initBufOffset
    jsr loadStackValue
    stq ptr1
    lda #1
    ldx #0
    jsr writeToMemBuf
    rts
.endproc

; This routine writes out the declaration initialization label
; for the first element of an embedded record or array. It also
; writes out an empty initializers label and size.
.proc writeArrayOrRecordInitLabel
    ldz #initBufOffset
    jsr loadStackValue
    stq ptr1
    ; Count the length of the label
    ldz #labelOffset
    jsr loadStackValue
    stq ptr2
    ldz #0
:   nop
    lda (ptr2),z
    beq :+
    inz
    bne :-
:   tza
    ldx #0
    jsr writeToMemBuf

    ; Add a ".1" to the label
    lda #'.'
    sta buffer
    lda #'1'
    sta buffer+1
    lda #0
    sta buffer+2
    ldz #initBufOffset
    jsr loadStackValue
    stq ptr1
    lda #<buffer
    sta ptr2
    lda #>buffer
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #3
    ldx #0
    jsr writeToMemBuf
    ldz #initBufOffset
    jsr loadStackValue
    stq ptr1
    lda #0
    sta buffer
    sta buffer+1
    lda #<buffer
    sta ptr2
    lda #>buffer
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #3
    ldx #0
    jsr writeToMemBuf
    rts
.endproc

; This routine writes out an empty element declaration label string,
; an empty element literals string, and a 0 for the number of literals.
; This is used for array element types that do not have literals.
.proc finishOutArrayBlock
    lda #0
    sta declBuf
    sta declBuf+1

    ldz #initBufOffset
    jsr loadStackValue
    stq ptr1
    lda #<declBuf
    sta ptr2
    lda #>declBuf
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3

    ; Empty element declaration block label
    lda #1
    ldx #0
    jsr writeToMemBuf

    ; Empty literals list
    lda #1
    ldx #0
    jsr writeToMemBuf

    ; Number of literals
    lda #2
    ldx #0
    jsr writeToMemBuf

    rts
.endproc

.proc writeStringElems
    lda #ARRAYDECL_STRING
    jsr writeArrayElemType

    ldz #declPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #decl::value
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    bne :+
    jsr finishOutArrayBlock
    rts

:   stq ptr2                ; save first string literal expression
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    ldz #initBufOffset
    jsr loadStackValue
    jsr pushQ               ; declaration block membuf
    ldq ptr2
    jsr pushQ               ; first string literal
    jsr addStringArrayLiterals
    rts
.endproc

.proc writeScalarElems
    lda #ARRAYDECL_SCALAR
    jsr writeArrayElemType

    ; ldz #declPtrOffset
    ; jsr loadStackValue
    ; stq ptr1
    ; ldz #decl::value
    ldz #exprInitOffset
    jsr loadStackValue
    jsr isQZero
    bne :+
    jsr finishOutArrayBlock
    rts

:   stq ptr2                ; save first literal expression
    ldz #expr::kind
    nop
    lda (ptr2),z
    cmp #EXPR_ARRAY_LITERAL
    bne :+
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
:   ; stq ptr2
    ldz #initBufOffset
    jsr loadStackValue
    stq ptr1
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr3
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr3
    ldz #type::size+1
    nop
    lda (ptr3),z
    pha
    dez
    nop
    lda (ptr3),z
    pha
    ldq ptr1
    jsr pushQ               ; declaration block membuf
    ldq ptr2
    jsr pushQ               ; first literal
    pla
    plx
    jsr pushAX              ; element size
    jsr addScalarArrayLiterals
    rts
.endproc

.proc writeRealElems
    lda #ARRAYDECL_REAL
    jsr writeArrayElemType

    ldz #declPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #decl::value
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    bne :+
    jsr finishOutArrayBlock
    rts

:   stq ptr2                ; save first real literal expression
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    ldz #initBufOffset
    jsr loadStackValue
    jsr pushQ               ; declaration block membuf
    ldq ptr2
    jsr pushQ               ; first real literal
    jsr addStringArrayLiterals
    rts
.endproc

; Array limit expression passed in Q.
; Array limit returned in A/X.
.proc getArrayLimit
    stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_BYTE_LITERAL
    bne :+
    jmp byteLiteral
:   cmp #EXPR_WORD_LITERAL
    bne :+
    jmp wordLiteral
:   cmp #EXPR_CHARACTER_LITERAL
    bne :+
    ldz #expr::value
    nop
    lda (ptr1),z
    ldx #0
    rts
:   cmp #EXPR_NAME
    beq :+
    lda #0
    tax
    rts

    ; Name
:   ldq ptr2
    jsr pushQ
    ldq ptr1
    ldz #expr::name
    jsr calcNamePtr
    stq ptr4
    jsr scopeLookup
    stq ptr1
    ldz #symbol::decl
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    jsr popQ
    stq ptr2
    ldz #decl::value
    neg
    neg
    nop
    lda (ptr1),z
    jmp getArrayLimit
.endproc

.proc byteLiteral
    ldz #expr::neg
    nop
    lda (ptr1),z
    bne :+
    ldz #expr::value
    nop
    lda (ptr1),z
    ldx #0
    rts

:   ldz #expr::value
    nop
    lda (ptr1),z
    neg
    clc
    adc #1
    ldx #0
    rts
.endproc

.proc wordLiteral
    ldz #expr::neg
    nop
    lda (ptr1),z
    bne :+
    ldz #expr::value+1
    nop
    lda (ptr1),z
    tax
    dez
    nop
    lda (ptr1),z
    rts

:   ldz #expr::value
    nop
    lda (ptr1),z
    sta intOp1
    inz
    nop
    lda (ptr1),z
    sta intOp1+1
    jsr invertInt16
    lda intOp1
    ldx intOp1+1
    rts
.endproc

.proc calcNumElements
    ldz #highBoundOffset
    nop
    lda (stackPointer),z
    sta intOp1
    inz
    nop
    lda (stackPointer),z
    sta intOp1+1
    ldz #lowBoundOffset
    nop
    lda (stackPointer),z
    sta intOp2
    inz
    nop
    lda (stackPointer),z
    sta intOp2+1
    jsr subInt16
    lda intOp1+1
    and #$7f
    beq :+
    jsr invertInt16
:   lda #1
    sta intOp2
    lda #0
    sta intOp2+1
    jsr addInt16
    ldz #numElementsOffset
    lda intOp1
    nop
    sta (stackPointer),z
    inz
    lda intOp1+1
    nop
    sta (stackPointer),z
    rts
.endproc
