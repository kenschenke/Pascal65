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

.code

.proc freeUnits
    ldq unitList
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

    ldq thisUnit
    jsr heapFree
    ldq thisUnit
    stq ptr1
    ldz #unit::next
    neg
    neg
    nop
    lda (ptr1),z
    stq thisUnit
    bra L1

L2: rts
.endproc
