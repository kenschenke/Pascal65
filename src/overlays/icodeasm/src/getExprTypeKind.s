;
; getExprTypeKind.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export getExprTypeKind

; Expression passed in Q
.proc getExprTypeKind
    stq ptr1
    ldz #expr::evalTypeKind
    nop
    lda (ptr1),z
    rts
.endproc
