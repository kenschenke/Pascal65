;
; dumpStmt.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; dumpStmt routine

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export dumpStmt

.import dumpDecl, level

.proc dumpStmt
    jsr isQZero
    bne :+
    rts

:   stq ptr1
    jsr pushQ

    inc level
    ldz #stmt::decl
    neg
    neg
    nop
    lda (ptr1),z
    jsr dumpDecl
    dec level

    jsr popQ
    rts
.endproc
