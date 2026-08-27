;
; isExprAFuncCall.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export isExprAFuncCall

; On exit, the Z flag is set if the expression is a function call
; Expression is passed in Q
.proc isExprAFuncCall
    stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_CALL
    rts
.endproc
