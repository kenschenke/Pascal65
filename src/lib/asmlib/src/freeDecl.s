;
; freeDecl.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; freeDecl routine

.include "ast.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export freeDecl

.import freeType, freeExpr, freeSymbol, freeSymtab, freeStmt, loadPtr
.import isQZero, rtPushQ, rtPopQ, heapFree, isHeapAllocated, peekQ

; Pointer to decl in Q
; Carry flag is set if the routine is to follow the "next" chain
.proc freeDecl
    jsr rtPushQ
L1: jsr peekQ
    jsr isQZero
    bne L2
    jsr rtPopQ
    rts

L2: jsr isHeapAllocated
    bne :+
    jsr rtPopQ
    rts

    ; Name
:   jsr peekQ
    stq ptr1
    ldz #decl::name
    jsr loadPtr
    jsr isQZero
    beq :+
    jsr heapFree

    ; Type
:   jsr peekQ
    stq ptr1
    ldz #decl::type
    jsr loadPtr
    jsr freeType

    ; Value
    jsr peekQ
    stq ptr1
    ldz #decl::value
    jsr loadPtr
    jsr freeExpr

    ; Code
    jsr peekQ
    stq ptr1
    ldz #decl::code
    jsr loadPtr
    sec
    jsr freeStmt

    ; Symtab
    jsr peekQ
    stq ptr1
    ldz #decl::symtab
    jsr loadPtr
    jsr freeSymtab

    ; Node
    jsr peekQ
    stq ptr1
    ldz #decl::node
    jsr loadPtr
    jsr freeSymbol

    ; UnitSymbtab
    jsr peekQ
    stq ptr1
    ldz #decl::unitSymtab
    jsr loadPtr
    jsr freeSymtab

    ; next
    jsr rtPopQ
    stq ptr1
    ldz #decl::next
    jsr loadPtr
    jsr rtPushQ

    ldq ptr1
    jsr heapFree
    jmp L1
.endproc
