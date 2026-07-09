;
; typeClone.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; typeClone routine

.include "ast.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export typeClone, savePtrs, restorePtrs, storePtr

.import typeCreate
.import exprClone, declClone, paramListClone, symbolClone
.import isQZero, rtPushQ, rtPopQ, rtPushA

; Pointer to type passed in Q
; Pointer to new type returned in Q
.proc typeClone
    jsr isQZero
    bne :+
    rts
:   stq ptr1

    ; Clone the subtype first
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L1
    stq ptr2                ; keep the subtype pointer in ptr2
    ; Is the subtype the same as the type?
    ldx #0
:   lda ptr1,x
    cmp ptr2,x
    bne NE
    inx
    cpx #4
    bne :-
    bra L1
NE: ldq ptr1
    jsr rtPushQ             ; store the type pointer on the stack
    ldq ptr2
    jsr typeClone           ; clone the subtype
    stq ptr2                ; subtype in ptr2
    jsr rtPopQ
    stq ptr1                ; put type back in ptr1
    bra L2

    ; There is no subtype - put null in ptr2
L1: stq ptr2

    ; Copy the paramFields
    ; If the type is a record or enumeration, paramFields is a chain of decls.
    ; If it's a procedure or function, paramFields is a chain of param_list.
L2: ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L3

    ; Copy the paramFields
    stq ptr3
    ldz #type::paramFields
    ldx #0
:   lda ptr3,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-

L3: ; Save the type ptr on the stack first
    ldq ptr1
    jsr rtPushQ

    ldz #type::kind
    nop
    lda (ptr1),z
    jsr rtPushA               ; kind
    lda #0
    jsr rtPushA               ; isConst
    ldq ptr2
    jsr rtPushQ               ; subtype
    ldq ptr3
    jsr rtPushQ               ; params
    jsr typeCreate
    stq ptr2                ; cloned type in ptr2
    jsr rtPopQ
    stq ptr1                ; original type in ptr1

    ; Clone the indextype
    jsr savePtrs
    ldz #type::indextype
    neg
    neg
    nop
    lda (ptr1),z
    jsr typeClone
    stq ptr3
    jsr restorePtrs
    ldz #type::indextype
    jsr storePtr

    ; Copy flags
    ldz #type::flags
    nop
    lda (ptr1),z
    ora #TYPE_FLAG_ISCLONED
    nop
    sta (ptr2),z

    ; Copy routinecode
    ldz #type::routineCode
    nop
    lda (ptr1),z
    nop
    sta (ptr2),z

    ; Copy the size
    ldz #type::size
    nop
    lda (ptr1),z
    nop
    sta (ptr2),z
    inz
    nop
    lda (ptr1),z
    nop
    sta (ptr2),z

    ; Copy the line number
    ldz #type::lineNumber
    nop
    lda (ptr1),z
    nop
    sta (ptr2),z
    inz
    nop
    lda (ptr1),z
    nop
    sta (ptr2),z

    ; Copy the name
    ldz #type::name
    ldx #0
:   nop
    lda (ptr1),z
    nop
    sta (ptr2),z
    inz
    inx
    cpx #NAMELEN
    bne :-

    ; Clone the min expression
L6: jsr savePtrs
    ldz #type::min
    neg
    neg
    nop
    lda (ptr1),z
    jsr exprClone
    stq ptr3
    jsr restorePtrs
    ldz #type::min
    jsr storePtr

    ; Clone the max expression
    jsr savePtrs
    ldz #type::max
    neg
    neg
    nop
    lda (ptr1),z
    jsr exprClone
    stq ptr3
    jsr restorePtrs
    ldz #type::max
    jsr storePtr

    ; Copy the symtab
    ldz #type::symtab
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr3
    ldz #type::symtab
    jsr storePtr

    ; Done
    ldq ptr2
    rts
.endproc

; This routine saves ptr1 and ptr2 to the stack
.proc savePtrs
    ldq ptr1
    jsr rtPushQ
    ldq ptr2
    jsr rtPushQ
    rts
.endproc

; This routine restores ptr1 and ptr2 from the stack
.proc restorePtrs
    jsr rtPopQ
    stq ptr2
    jsr rtPopQ
    stq ptr1
    rts
.endproc

; This routine stores the pointer in ptr3 into the
; structure in ptr2. Z contains the offset in the structure.
.proc storePtr
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
