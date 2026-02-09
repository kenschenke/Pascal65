;
; checkIntegerBaseType.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

exprOffset = 0

.export checkIntegerBaseType

.import loadStackValue, exprTypeCheck, typeCheckError

.bss

exprType: .res .sizeof(type)

.code

.proc checkIntegerBaseType
    ldz #exprOffset
    jsr loadStackValue
    jsr isQZero
    beq DN

    jsr pushQ
    jsr pushQZero
    lda #<exprType
    ldx #>exprType
    ldy #0
    ldz #0
    jsr pushQ
    lda #0
    jsr pushA
    jsr exprTypeCheck

    lda #<exprType
    ldx #>exprType
    ldy #0
    ldz #0
    jsr getBaseType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_INTEGER
    beq DN
    lda #errIncompatibleTypes
    jsr typeCheckError

DN: jsr popQ
    rts
.endproc
