;
; stmtClone.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; stmtClone routine

.include "ast.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export stmtClone

.import savePtrs, restorePtrs, storePtr, declClone, exprClone
.import rtPopQ, rtPushQ, heapAlloc, isQZero

.proc stmtClone
    jsr isQZero
    bne :+
    rts

:   jsr rtPushQ

    ; Allocate a stmt structure and store the pointer in ptr2
    lda #.sizeof(stmt)
    ldx #0
    jsr heapAlloc
    stq ptr2

    ; Zero out the new stmt
    lda #0
    ldz #0
:   nop
    sta (ptr2),z
    inz
    cpz #.sizeof(stmt)
    bne :-

    ; Put the original structure pointer in ptr1
    jsr rtPopQ
    stq ptr1

    ; Copy the kind
    ldz #stmt::kind
    nop
    lda (ptr1),z
    nop
    sta (ptr2),z

    ; Clone the decl
    jsr savePtrs
    ldz #stmt::decl
    neg
    neg
    nop
    lda (ptr1),z
    jsr declClone
    stq ptr3
    jsr restorePtrs
    ldz #stmt::decl
    jsr storePtr

    ; Clone the interfaceDecl
    jsr savePtrs
    ldz #stmt::interfaceDecl
    neg
    neg
    nop
    lda (ptr1),z
    jsr declClone
    stq ptr3
    jsr restorePtrs
    ldz #stmt::interfaceDecl
    jsr storePtr

    ; Clone the init_expr
    jsr savePtrs
    ldz #stmt::init_expr
    neg
    neg
    nop
    lda (ptr1),z
    jsr exprClone
    stq ptr3
    jsr restorePtrs
    ldz #stmt::init_expr
    jsr storePtr

    ; Clone the expr
    jsr savePtrs
    ldz #stmt::expr
    neg
    neg
    nop
    lda (ptr1),z
    jsr exprClone
    stq ptr3
    jsr restorePtrs
    ldz #stmt::expr
    jsr storePtr

    ; Clone the to_expr
    jsr savePtrs
    ldz #stmt::to_expr
    neg
    neg
    nop
    lda (ptr1),z
    jsr exprClone
    stq ptr3
    jsr restorePtrs
    ldz #stmt::to_expr
    jsr storePtr

    ; Copy isDownto
    ldz #stmt::isDownTo
    nop
    lda (ptr1),z
    nop
    sta (ptr2),z

    ; Clone the body
    jsr savePtrs
    ldz #stmt::body
    neg
    neg
    nop
    lda (ptr1),z
    jsr stmtClone
    stq ptr3
    jsr restorePtrs
    ldz #stmt::body
    jsr storePtr

    ; Clone the else_body
    jsr savePtrs
    ldz #stmt::else_body
    neg
    neg
    nop
    lda (ptr1),z
    jsr stmtClone
    stq ptr3
    jsr restorePtrs
    ldz #stmt::else_body
    jsr storePtr

    ; Clone the next
    jsr savePtrs
    ldz #stmt::next
    neg
    neg
    nop
    lda (ptr1),z
    jsr stmtClone
    stq ptr3
    jsr restorePtrs
    ldz #stmt::next
    jsr storePtr

    ; Copy the lineNumber
    ldz #stmt::lineNumber
    nop
    lda (ptr1),z
    nop
    sta (ptr2),z
    inz
    nop
    lda (ptr1),z
    nop
    sta (ptr2),z

    ldq ptr2
    rts
.endproc
