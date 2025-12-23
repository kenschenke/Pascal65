;
; freeSymtab.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; freeSymtab routine

.include "tree.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export freeSymtab

.import freeSymbol, loadPtr, heapFree, rtPopQ, rtPushQ, isQZero, isHeapAllocated, peekQ

.bss

symPtr: .res 4

.code

.proc freeSymtab
    stq symPtr
    jsr isQZero
    bne :+
    rts
:   jsr isHeapAllocated
    bne :+
    rts
:   ldq symPtr
    stq ptr1
    jsr rtPushQ

    ; LeftChild
    ldz #TREENODE::left
    jsr loadPtr
    jsr freeSymtab

    ; RightChild
    jsr peekQ
    stq ptr1
    ldz #TREENODE::right
    jsr loadPtr
    jsr freeSymtab

    ; Symbol
    jsr peekQ
    stq ptr1
    ldz #TREENODE::data
    jsr loadPtr
    jsr freeSymbol

    jsr rtPopQ
    jsr heapFree
    rts
.endproc
