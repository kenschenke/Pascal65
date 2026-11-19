;
; orderUnits.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; orderUnits routine
;
; The parser adds a unit to the units list when a module first names it, so
; a unit that only another unit uses comes after that unit. A unit must be
; resolved and type checked after the units it uses, and its variables are
; numbered and initialized in the list's order, so orderUnits puts each unit
; after the units its Uses name, before resolveUnits resolves them. Units
; that don't depend on each other keep their order, so the program's own
; units stay in its Uses order. A cycle is broken where it's found.

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export orderUnits

.import units

.bss

count: .res 1               ; units in the list
units1: .res 4              ; heap block: a pointer to each unit, in order
seen: .res 4                ; heap block: a byte for each, non-zero once seen
newHead: .res 4             ; the list being built
newTail: .res 4
mainIdx: .res 1
idx: .res 1
fk: .res 1
thisUnit: .res 4

.code

.proc orderUnits
    ; Count the units. One or none needs no ordering.
    lda #0
    sta count
    ldq units
L1: jsr isQZero
    beq L2
    inc count
    stq ptr1
    ldz #unit::next
    neg
    neg
    nop
    lda (ptr1),z
    bra L1
L2: lda count
    cmp #2
    bcs :+
    rts

    ; The pointers and the seen flags, which heapAlloc zeros
:   lda count
    sta intOp1
    lda #0
    sta intOp1+1
    asl intOp1
    rol intOp1+1
    asl intOp1
    rol intOp1+1
    lda intOp1
    ldx intOp1+1
    jsr heapAlloc
    stq units1
    lda count
    ldx #0
    jsr heapAlloc
    stq seen

    ; Keep a pointer to each unit, since the walk rewrites the links
    lda #0
    sta mainIdx
    ldq units
L3: stq thisUnit
    jsr isQZero
    beq L4
    lda mainIdx
    jsr unitPtr
    ldz #0
    ldx #0
:   lda thisUnit,x
    nop
    sta (ptr3),z
    inz
    inx
    cpx #4
    bne :-
    inc mainIdx
    ldq thisUnit
    stq ptr1
    ldz #unit::next
    neg
    neg
    nop
    lda (ptr1),z
    bra L3

    ; Visit each unit in its order
L4: lda #0
    tax
    tay
    taz
    stq newHead
    stq newTail
    sta mainIdx
L5: lda mainIdx
    cmp count
    beq L6
    jsr visit
    inc mainIdx
    bra L5

    ; End the new list, then free the blocks
L6: ldq newTail
    stq ptr1
    ldz #unit::next
    lda #0
    ldx #4
:   nop
    sta (ptr1),z
    inz
    dex
    bne :-
    ldq newHead
    stq units
    ldq units1
    jsr heapFree
    ldq seen
    jmp heapFree
.endproc

; This routine adds the unit numbered in A to the new list after the units
; it uses, unless it's already there.
.proc visit
    sta idx
    jsr seenPtr
    ldz #0
    nop
    lda (ptr3),z
    beq :+
    rts
:   lda #1
    nop
    sta (ptr3),z

    lda idx
    jsr pushA               ; this unit's number
    lda idx
    jsr unitPtr
    ldz #0
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr1
    ldz #unit::astRoot
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero             ; A unit that wasn't parsed uses nothing
    beq AP
    stq ptr1
    ldz #decl::code
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq AP

    ; The Uses in its interface, then in its implementation
    jsr pushQ               ; the code block
    jsr loadTop
    stq ptr1
    ldz #stmt::interfaceDecl
    neg
    neg
    nop
    lda (ptr1),z
    jsr visitChain
    jsr loadTop
    stq ptr1
    ldz #stmt::decl
    neg
    neg
    nop
    lda (ptr1),z
    jsr visitChain
    jsr popQ                ; the code block

AP: jsr popA                ; this unit's number
    jmp append
.endproc

; This routine visits the unit each Uses declaration in the chain in Q
; names
.proc visitChain
L1: jsr isQZero
    bne :+
    rts
:   jsr pushQ               ; the declaration
    jsr loadTop
    stq ptr1
    ldz #decl::kind
    nop
    lda (ptr1),z
    cmp #DECL_USES
    bne NX
    jsr findIndex
    bcs NX
    jsr visit
NX: jsr popQ
    stq ptr1
    ldz #decl::next
    neg
    neg
    nop
    lda (ptr1),z
    bra L1
.endproc

; This routine finds the unit named by the declaration in ptr1. Its number
; is returned in A with the carry clear, or the carry is set if there is
; none.
.proc findIndex
    ldq ptr1
    ldz #decl::name
    stz intOp32
    ldz #0
    stz intOp32+1
    stz intOp32+2
    stz intOp32+3
    clc
    adcq intOp32
    stq ptr2                ; the name

    lda #0
    sta fk
L1: lda fk
    cmp count
    bne :+
    sec
    rts
:   jsr unitPtr
    ldz #0
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr4                ; the unit; unit::name is its first member
    ldz #0
L2: nop
    lda (ptr4),z
    nop
    cmp (ptr2),z
    bne NX
    cmp #0
    beq FD
    inz
    bne L2
NX: inc fk
    bra L1
FD: lda fk
    clc
    rts
.endproc

; This routine adds the unit numbered in A to the end of the new list
.proc append
    jsr unitPtr
    ldz #0
    neg
    neg
    nop
    lda (ptr3),z
    stq thisUnit
    ldq newTail
    jsr isQZero
    bne :+
    ldq thisUnit
    stq newHead
    bra L1
:   stq ptr1
    ldz #unit::next
    ldx #0
:   lda thisUnit,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
L1: ldq thisUnit
    stq newTail
    rts
.endproc

; This routine points ptr3 at the pointer to the unit numbered in A
.proc unitPtr
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    asl intOp32
    rol intOp32+1
    asl intOp32
    rol intOp32+1
    ldq units1
    clc
    adcq intOp32
    stq ptr3
    rts
.endproc

; This routine points ptr3 at the seen flag of the unit numbered in A
.proc seenPtr
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq seen
    clc
    adcq intOp32
    stq ptr3
    rts
.endproc

; This routine loads the pointer on top of the runtime stack into Q
.proc loadTop
    ldz #0
    neg
    neg
    nop
    lda (stackPointer),z
    rts
.endproc
