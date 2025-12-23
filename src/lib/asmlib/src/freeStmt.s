;
; freeStmt.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; freeStmt routine

.include "ast.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export freeStmt

.import freeDecl, freeExpr, loadPtr, rtPushQ, rtPopQ, isQZero, heapFree, peekQ

.proc freeStmt
    jsr rtPushQ
L1: jsr peekQ
    jsr isQZero
    bne L2
    jsr rtPopQ
    rts

L2: jsr peekQ
    stq ptr1
    ldz #stmt::decl
    jsr loadPtr
    jsr freeDecl

    ; interfaceDecl
    jsr peekQ
    stq ptr1
    ldz #stmt::interfaceDecl
    jsr loadPtr
    jsr freeDecl

    ; expr
    jsr peekQ
    stq ptr1
    ldz #stmt::expr
    jsr loadPtr
    jsr freeExpr

    ; init_expr
    jsr peekQ
    stq ptr1
    ldz #stmt::init_expr
    jsr loadPtr
    jsr freeExpr

    ; to_expr
    jsr peekQ
    stq ptr1
    ldz #stmt::to_expr
    jsr loadPtr
    jsr freeExpr

    ; body
    jsr peekQ
    stq ptr1
    ldz #stmt::body
    jsr loadPtr
    jsr freeStmt

    ; else_body
    jsr peekQ
    stq ptr1
    ldz #stmt::else_body
    jsr loadPtr
    jsr freeStmt

    ; next
    jsr rtPopQ
    stq ptr1
    ldz #stmt::next
    jsr loadPtr
    jsr rtPushQ

    ldq ptr1
    jsr heapFree
    jmp L1
.endproc
