;
; icodeRoutineDeclarations.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

declOffset = 0

.export icodeRoutineDeclarations

.import loadStackValue, icodeRoutineDeclaration

; Root declaration passed in Q
.proc icodeRoutineDeclarations
    jsr pushQ

    ; Loop through declarations
L1: ldz #declOffset
    jsr loadStackValue
    jsr isQZero
    beq DN

    stq ptr1
    ldz #decl::symtab
    neg
    neg
    nop
    lda (ptr1),z
    jsr scopeEnterSymtab

    ldz #declOffset
    jsr loadStackValue
    stq ptr1
    ldz #decl::kind
    nop
    lda (ptr1),z
    cmp #DECL_TYPE
    bne NX

    ldz #decl::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    ldz #type::kind
    nop
    lda (ptr2),z
    cmp #TYPE_FUNCTION
    beq L2
    cmp #TYPE_PROCEDURE
    bne NX

L2: ldq ptr1
    jsr pushQ
    ldq ptr2
    jsr pushQ
    jsr icodeRoutineDeclaration

NX: jsr scopeExit
    ldz #declOffset
    jsr loadStackValue
    stq ptr1
    ldz #decl::next
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldx #0
    ldz #declOffset
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    jmp L1

DN: jsr popQ
    rts
.endproc
