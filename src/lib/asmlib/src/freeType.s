;
; freeType.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; freeType routine

.include "ast.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export freeType

.import freeParamList, freeSymbol, freeSymtab, freeExpr, freeDecl, loadPtr, isQZero
.import rtPushQ, rtPopQ, heapFree, isHeapAllocated, peekQ

; Pointer to type in Q
.proc freeType
    jsr isQZero
    bne :+
    rts
:   jsr rtPushQ
    jsr peekQ
    jsr isHeapAllocated
    bne :+
    jsr rtPopQ
    rts

    ; Subtype
:   jsr peekQ
    stq ptr1
    ldz #type::subtype
    jsr loadPtr
    jsr freeType

    ; Indextype
    jsr peekQ
    stq ptr1
    ldz #type::indextype
    jsr loadPtr
    jsr freeType

    ; Min
    jsr peekQ
    stq ptr1
    ldz #type::min
    jsr loadPtr
    jsr freeExpr

    ; Max
    jsr peekQ
    stq ptr1
    ldz #type::max
    jsr loadPtr
    jsr freeExpr

    ; Symtab
    jsr peekQ
    stq ptr1
    ldz #type::symtab
    jsr loadPtr
    jsr freeSymtab

    ; paramFields
    jsr freeParamFields

    ; Name
    jsr peekQ
    stq ptr1
    ldz #type::name
    jsr loadPtr
    jsr isQZero
    beq :+
    jsr heapFree

:   jsr rtPopQ
    jsr heapFree
    rts
.endproc

.proc freeParamFields
    jsr peekQ
    stq ptr1

    ldz #type::paramFields
    jsr loadPtr
    jsr isQZero
    beq L2

    stq ptr2
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_FUNCTION
    beq L1
    cmp #TYPE_PROCEDURE
    beq L1
    cmp #TYPE_PROGRAM
    beq L1

    ldq ptr2
    jsr freeDecl
    bra L2

L1: ldq ptr2
    jsr freeParamList

L2: rts
.endproc
