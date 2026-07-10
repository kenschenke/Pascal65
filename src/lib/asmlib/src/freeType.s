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
.import rtPushQ, rtPopQ, heapFree, peekQ

; Pointer to type in Q
.proc freeType
    jsr isQZero
    bne :+
    rts

    ; Subtype
:   stq ptr1
    jsr rtPushQ
    ldz #type::subtype
    jsr loadPtr
    stq ptr2
    ldx #0
:   lda ptr1,x
    cmp ptr2,x
    bne L1
    inx
    cpx #4
    bne :-
    bra L2
L1: ldq ptr2
    jsr freeType

    ; Indextype
L2: jsr peekQ
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
    ldz #type::flags
    nop
    lda (ptr1),z
    and #TYPE_FLAG_ISCLONED
    bne :+
    ldz #type::symtab
    jsr loadPtr
    jsr freeSymtab

    ; paramFields
:   jsr peekQ
    stq ptr1
    ldz #type::flags
    nop
    lda (ptr1),z
    and #TYPE_FLAG_ISCLONED
    bne :+
    jsr freeParamFields

:   jsr rtPopQ
    jsr heapFree
    rts
.endproc

.proc freeParamFields
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
