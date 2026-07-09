;
; getArraySize.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; getArraySize routine

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

; This routine's local variables
maxOffset = 0
minOffset = 2
subtypeOffset = 4
indexTypeOffset = 8

; The caller's local variables (getTypeSize)
sizeOffset = 12
typeOffset = 14

.export getArraySize

.import getSubrangeLimit, getTypeSize, calcNamePtr

; The array type is in ptr1 on entry
; The total array size is returned in A/X.
.proc getArraySize
    jsr pushQZero           ; indexType
    jsr pushQZero           ; subtype
    lda #0
    tax
    jsr pushAX              ; min
    lda #0
    tax
    jsr pushAX              ; max

    ; Look up the array element type
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr4
    ldz #subtypeOffset
    jsr storePtr

    ; Look up the array index type
    ldz #type::indextype
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr4
    ldz #indexTypeOffset
    jsr storePtr

    ldz #type::kind
    nop
    lda (ptr4),z
    cmp #TYPE_DECLARED
    bne :+
    jsr getDeclaredArraySize
    bra L1
:   ldz #type::min
    neg
    neg
    nop
    lda (ptr4),z
    jsr getSubrangeLimit
    ldz #minOffset
    jsr storeAX
    ldz #indexTypeOffset
    jsr getPtr
    ldz #type::max
    neg
    neg
    nop
    lda (ptr4),z
    jsr getSubrangeLimit
    ldz #maxOffset
    jsr storeAX

    ; Get the size of each array element
L1: ldz #subtypeOffset
    jsr getPtr
    jsr getTypeSize
    ; Store the array element size in the subtype
    pha
    phx
    ldz #subtypeOffset
    jsr getPtr
    ldz #type::size+1
    pla
    nop
    sta (ptr4),z
    dez
    pla
    nop
    sta (ptr4),z

    ; Get the size of the index type
    ldz #indexTypeOffset
    jsr getPtr
    jsr getTypeSize
    ; Store the index size in the indextype
    pha
    phx
    ldz #indexTypeOffset
    jsr getPtr
    ldz #type::size+1
    pla
    nop
    sta (ptr4),z
    dez
    pla
    nop
    sta (ptr4),z

    ; Calculate the total array size
    ; arraySize = elementSize * (max - min + 1) + 6
    ldz #subtypeOffset
    jsr getPtr
    ldz #type::size
    nop
    lda (ptr4),z
    sta intOp1
    inz
    nop
    lda (ptr4),z
    sta intOp1+1
    ldz #maxOffset
    jsr getAX
    sta intOp2
    stx intOp2+1
    ldz #minOffset
    jsr getAX
    sta tmp1
    stx tmp2
    ; max - min
    lda intOp2
    sec
    sbc tmp1
    sta intOp2
    lda intOp2+1
    sbc tmp2
    sta intOp2+1
    ; add 1
    inw intOp2
    ; element size * (max - min + 1)
    jsr multInt16
    ; add 6 (array header size)
    lda intOp1
    clc
    adc #6
    sta intOp1
    lda intOp1+1
    adc #0
    sta intOp1+1
    ; Pop local variables off stack
    jsr popAX
    jsr popAX
    jsr popQ
    jsr popQ
    lda intOp1
    ldx intOp1+1
    rts
.endproc

; Indextype is still in ptr4
.proc getDeclaredArraySize
    ldq ptr4
    ldz #type::name
    jsr calcNamePtr
    stq ptr4                ; name in ptr4
    jsr scopeLookup
    jsr isQZero
    bne :+
    rts
:   stq ptr1                ; symbol node in ptr1
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2                ; symbol type in ptr2
    ldz #type::kind
    nop
    lda (ptr2),z
    cmp #TYPE_ENUMERATION
    bne :+
    ldz #type::max
    neg
    neg
    nop
    lda (ptr2),z
    jsr getSubrangeLimit
    ldz #maxOffset
    jsr storeAX
    rts
:   cmp #TYPE_SUBRANGE
    bne :+
    ldq ptr2
    jsr pushQ               ; save the symbol type on the stack
    ldz #type::min
    neg
    neg
    nop
    lda (ptr2),z
    jsr getSubrangeLimit
    pha
    phx
    jsr popQ
    stq ptr2
    plx
    pla
    ldz #minOffset
    jsr storeAX
    ldq ptr2
    jsr pushQ
    ldz #type::max
    neg
    neg
    nop
    lda (ptr2),z
    jsr getSubrangeLimit
    pha
    phx
    jsr popQ
    stq ptr2
    plx
    pla
    ldz #maxOffset
    jsr storeAX
    rts
:   cmp #TYPE_BYTE
    beq L1
    cmp #TYPE_WORD
    beq L1
    bra L2
L1: ldz #symbol::decl
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr3                ; decl in ptr3
    ldz #decl::value
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr4                ; value expression in ptr4
    ldz #expr::value+1
    nop
    lda (ptr4),z
    txa
    dez
    nop
    lda (ptr4),z
    ldz #maxOffset
    jsr storeAX
L2: ldq ptr2
    jsr pushQ
    ldq ptr2
    jsr getTypeSize
    pha
    phx
    jsr popQ
    stq ptr2
    ldz #type::size+1
    pla
    nop
    sta (ptr2),z
    dez
    pla
    nop
    sta (ptr2),z
    rts
.endproc

; This routine stores the 16-bit value in A/X to the runtime stack
; at offset Z.
.proc storeAX
    nop
    sta (stackPointer),z
    inz
    txa
    nop
    sta (stackPointer),z
    rts
.endproc

; This routine reads the 16-bit value in A/X from the runtime stack
; at offset Z
.proc getAX
    inz
    nop
    lda (stackPointer),z
    tax
    dez
    nop
    lda (stackPointer),z
    rts
.endproc

; This routine reads a pointer from the stack offset in Z
; and stores in ptr4.
.proc getPtr
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr4
    rts
.endproc

; This routine stores in the pointer in ptr4 to the
; location on the stack offset in Z
.proc storePtr
    ldx #0
:   lda ptr4,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    rts
.endproc