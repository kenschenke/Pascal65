;
; freeUnits.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; freeUnits routine

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export freeUnits

.import unitList

.bss

thisUnit: .res 4
nextUnit: .res 4

.code

; This routine frees every unit. Their statements and values go first,
; while every unit's types are still there: an expression's evaluated type
; shares the declared types, also another unit's, and the System unit is
; first in the list.
.proc freeUnits
    ldq unitList
B1: stq thisUnit
    jsr isQZero
    beq B2
    stq ptr1
    ldz #unit::astRoot
    neg
    neg
    nop
    lda (ptr1),z
    jsr astFreeBodies
    ldq thisUnit
    stq ptr1
    ldz #unit::next
    neg
    neg
    nop
    lda (ptr1),z
    bra B1

B2: ldq unitList
    stq thisUnit

L1: ldq thisUnit
    jsr isQZero
    beq L2

    stq ptr1
    ldz #unit::astRoot
    neg
    neg
    nop
    lda (ptr1),z
    jsr astFree

    ; The next unit, read before this one is freed
    ldq thisUnit
    stq ptr1
    ldz #unit::next
    neg
    neg
    nop
    lda (ptr1),z
    stq nextUnit
    ldq thisUnit
    jsr heapFree
    ldq nextUnit
    stq thisUnit
    bra L1

L2: rts
.endproc
