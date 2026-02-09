;
; checkBoolOperand.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"
.include "error.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export checkBoolOperand

.import typeCheckError

.proc checkBoolOperand
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_BOOLEAN
    beq :+
    lda #errIncompatibleTypes
    jsr typeCheckError
:   rts
.endproc
