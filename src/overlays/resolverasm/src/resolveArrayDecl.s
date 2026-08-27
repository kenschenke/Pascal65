;
; resolveArrayDecl.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; resolveArrayDecl routine

.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "zeropage.inc"

.export resolveArrayDecl

.import getTypePtr, getTypeSize, resolverError

.proc resolveArrayDecl
    ; Get the declaration type
    jsr getTypePtr              ; type in ptr1
    ldz #type::indextype
    neg
    neg
    nop
    lda (ptr1),z
    jsr getTypeSize
    sta intOp1
    stx intOp1+1
    lda #2
    sta intOp2
    lda #0
    sta intOp2+1
    jsr gtInt16
    beq :+
    lda #errInvalidIndexType
    jsr resolverError
:   rts
.endproc
