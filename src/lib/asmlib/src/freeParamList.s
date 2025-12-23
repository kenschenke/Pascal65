;
; freeParamList.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; freeParamList routine

.include "ast.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export freeParamList

.import freeType, loadPtr, rtPopQ, rtPushQ, heapFree, isQZero, peekQ

.proc freeParamList
L1: jsr isQZero
    beq L2

    stq ptr1
    jsr rtPushQ

    ; Name
    ldz #param_list::name
    jsr loadPtr
    jsr isQZero
    beq :+
    jsr heapFree

    ; Type
:   jsr peekQ
    stq ptr1
    ldz #param_list::type
    jsr loadPtr
    jsr freeType

    ; Next
    jsr rtPopQ
    stq ptr1
    ldz #param_list::next
    jsr loadPtr
    jsr rtPushQ
    ldq ptr1
    jsr heapFree
    jsr rtPopQ
    bra L1

L2: rts
.endproc
