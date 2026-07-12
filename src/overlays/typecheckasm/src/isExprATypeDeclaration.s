;
; isExprATypeDeclaration.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export isExprATypeDeclaration

; Expression passed in Q.
; On exit, the Z flag is set if the expression is a type declaration.
.proc isExprATypeDeclaration
    stq ptr1
    ldz #expr::kind
    cmp #EXPR_NAME
    bne DN

    ldz #expr::name
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr4
    jsr scopeLookup
    stq ptr1
    jsr isQZero
    beq NO
    ldz #symbol::decl
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq NO
    stq ptr1

    ldz #decl::kind
    nop
    lda (ptr1),z
    cmp #DECL_TYPE
    rts

NO: lda #1
DN: rts
.endproc
