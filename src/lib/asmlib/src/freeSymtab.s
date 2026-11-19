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

.import freeSymbol, loadPtr, heapFree, rtPopQ, rtPushQ, isQZero, peekQ

.ifdef __DEBUG__
.import isHeapAllocated
.endif

.bss

symPtr: .res 4

.code

; This routine frees a symbol table: each node and its symbol.
; Input: the root node in Q
;
; A table whose names were added in order is a chain as long as the table,
; so the walk keeps the nodes still to free on the runtime stack, not in
; calls: a recursive walk on a long chain ran out of CPU stack. A zero
; below them marks where this call's nodes end, since freeSymbol can
; free a record's table on the way.
.proc freeSymtab
    jsr isQZero
    bne :+
    rts
:   stq symPtr
    lda #0
    tax
    tay
    taz
    jsr rtPushQ             ; the end marker
    ldq symPtr
    jsr rtPushQ

L1: jsr rtPopQ
    jsr isQZero
    bne :+
    rts                     ; the end marker
:   stq symPtr
.ifdef __DEBUG__
    jsr isHeapAllocated
    bne :+
    ldz #$13
    brk
    rts
:   ldq symPtr
.endif

    ; The children, if any, to free after this node
    stq ptr1
    ldz #TREENODE::left
    jsr loadPtr
    jsr isQZero
    beq :+
    jsr rtPushQ
:   ldq symPtr
    stq ptr1
    ldz #TREENODE::right
    jsr loadPtr
    jsr isQZero
    beq :+
    jsr rtPushQ

    ; The symbol, then the node
:   ldq symPtr
    jsr rtPushQ
    jsr peekQ
    stq ptr1
    ldz #TREENODE::data
    jsr loadPtr
    jsr freeSymbol
    jsr rtPopQ
    jsr heapFree
    bra L1
.endproc
