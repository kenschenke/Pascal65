;
; evalType.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; cloneEvalType and freeEvalType routines
;
; An expression's evaluated type (expr::evalType) is a shallow copy of the
; type the type checker worked out for it. It owns only its name and a
; temporary subtype (TYPE_FLAG_ISTEMP). Its other pointers (a subtype that
; isn't temporary, the index type, limits, symbol table and fields) are
; the declared types', which outlive the expression. These are the rules
; freeTempType in the type checker uses for its type blocks.

.include "ast.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export cloneEvalType, freeEvalType

.import nameClone, typeClone, freeType, heapAlloc, heapFree, loadPtr
.import isQZero, rtPushQ, rtPopQ, peekQ

.ifdef __DEBUG__
.import isHeapAllocated
.endif

.bss

srcType: .res 4
newType: .res 4

.code

; This routine makes an expression's evaluated type from the type in Q.
; The new type is returned in Q.
.proc cloneEvalType
    jsr isQZero
    bne :+
    rts
:   stq srcType
    lda #.sizeof(type)
    ldx #0
    jsr heapAlloc
    stq newType
    stq ptr2
    ldq srcType
    stq ptr1
    ldz #0
:   nop
    lda (ptr1),z
    nop
    sta (ptr2),z
    inz
    cpz #.sizeof(type)
    bne :-

    ; Like typeClone, mark it so freeType leaves the fields alone
    ldz #type::flags
    nop
    lda (ptr2),z
    ora #TYPE_FLAG_ISCLONED
    nop
    sta (ptr2),z

    ; Its own copy of the name
    ldz #type::name
    jsr loadPtr             ; ptr1 is the source
    jsr isQZero
    beq L1
    jsr nameClone
    stq ptr3
    lda #type::name
    jsr storeNew

    ; Its own copy of a temporary subtype. A subtype that is the source
    ; itself isn't kept.
L1: ldq srcType
    stq ptr1
    ldz #type::subtype
    jsr loadPtr
    jsr isQZero
    beq DN
    stq ptr3
    ldx #0
:   lda ptr3,x
    cmp srcType,x
    bne L2
    inx
    cpx #4
    bne :-
    lda #0
    tax
    tay
    taz
    bra L3
L2: ldz #type::flags
    nop
    lda (ptr3),z
    and #TYPE_FLAG_ISTEMP
    beq DN                  ; shared
    ldq ptr3
    jsr typeClone
L3: stq ptr3
    lda #type::subtype
    jsr storeNew

DN: ldq newType
    rts
.endproc

; This routine stores the pointer in ptr3 in newType at the offset in A.
.proc storeNew
    pha
    ldq newType
    stq ptr2
    pla
    taz
    ldx #0
:   lda ptr3,x
    nop
    sta (ptr2),z
    inz
    inx
    cpx #4
    bne :-
    rts
.endproc

; This routine frees an expression's evaluated type, passed in Q.
.proc freeEvalType
    jsr isQZero
    bne :+
    rts
:   jsr rtPushQ
.ifdef __DEBUG__
    jsr peekQ
    jsr isHeapAllocated
    bne :+
    jsr rtPopQ
    ldz #$14
    brk
    rts
:
.endif

    ; Name
    jsr peekQ
    stq ptr1
    ldz #type::name
    jsr loadPtr
    jsr isQZero
    beq :+
    jsr heapFree

    ; A temporary subtype
:   jsr peekQ
    stq ptr1
    ldz #type::subtype
    jsr loadPtr
    jsr isQZero
    beq L1
    stq ptr1
    ldz #type::flags
    nop
    lda (ptr1),z
    and #TYPE_FLAG_ISTEMP
    beq L1
    ldq ptr1
    jsr freeType

L1: jsr rtPopQ
    jmp heapFree
.endproc
