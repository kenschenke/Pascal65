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
.import exprClone, declClone, paramListClone, symbolClone, nameClone
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
    ldq ptr1
    jsr rtPushQ               ; store the type pointer on the stack
    ldq ptr2
    jsr typeClone           ; clone the subtype
    stq ptr2                ; subtype in ptr2
    jsr rtPopQ
    stq ptr1                ; put type back in ptr1
    bra L2

    ; There is no subtype - put null in ptr2
L1: stq ptr2

    ; Clone the paramFields
    ; If the type is a record, paramFields is a chain of decls.
    ; If it's a procedure or function, paramFields is a chain of param_list.
L2: ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L3

    ; Clone param fields
    stq ptr3
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_RECORD
    bne :+
    jsr cloneRecordFields
    bra L3
:   cmp #TYPE_PROCEDURE
    bne :+
    jsr cloneRoutineParams
    bra L3
:   cmp #TYPE_FUNCTION
    bne L3
    jsr cloneRoutineParams
    bra L3
    lda #0
    tax
    tay
    taz

L3: stq ptr3

    ; Save the type ptr on the stack first
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

    ; Clone name
    ldz #type::name
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L6
    stq ptr3
    jsr savePtrs
    ldq ptr3
    jsr nameClone
    stq ptr3
    jsr restorePtrs
    ldz #type::name
    jsr storePtr

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

; This routine clones a chain of record fields (decl structures).
; The first decl in the chain is passed in ptr3.
; The first in the chain is returned in Q.
.proc cloneRecordFields
    jsr savePtrs
    ldq ptr3
    sec
    jsr declClone
    stq ptr3
    jsr restorePtrs
    ldq ptr3
    rts
.endproc

; This routine clones a chain of routine parameters (param_list structures).
; The first in the chain is returned in Q.
.proc cloneRoutineParams
    jsr savePtrs
    ldq ptr3
    jsr paramListClone
    stq ptr3
    jsr restorePtrs
    ldq ptr3
    rts
.endproc
