;
; checkStdParms.s
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
.include "typecheck.inc"
.include "4510macros.inc"

allowedParmsOffset = 0
exprOffset = allowedParmsOffset + 1

.export checkStdParms

.import loadStackValue, typeCheckError, isTypeInteger, exprTypeCheck
.import loadQPtr1, typeErrIncompatible, typeErrParamCount

.bss

allowedParams: .res 1
exprType: .res .sizeof(type)

.code

.proc checkStdParms
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    jsr isQZero
    bne :+
    jsr typeErrParamCount   ; no parameters
    jmp DN
:
    ; There should be one parameter
    ldz #expr::right
    jsr loadQPtr1
    jsr isQZero
    beq :+
    jsr typeErrParamCount
    ldz #exprOffset             ; typeCheckError changes ptr1
    jsr loadStackValue
    stq ptr1

    ; Call exprTypeCheck
:   ldz #expr::left
    jsr loadQPtr1
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
    ldx #type::kind
    sta exprType,x

    ; Look up the allowedParams parameter and cache it for simplicity.
    ldz #allowedParmsOffset
    nop
    lda (stackPointer),z
    sta allowedParams

    ; Check the allowed parameters against exprType
    lda allowedParams
    and #STDPARM_CHAR
    beq :+
    lda exprType
    cmp #TYPE_CHARACTER
    beq DN
:   lda allowedParams
    and #STDPARM_ENUM
    beq :+
    lda exprType
    cmp #TYPE_ENUMERATION
    beq DN
    cmp #TYPE_ENUMERATION_VALUE
    beq DN
:   lda allowedParams
    and #STDPARM_INTEGER
    beq :+
    lda exprType
    jsr isTypeInteger
    beq DN
:   lda allowedParams
    and #STDPARM_REAL
    beq :+
    lda exprType
    cmp #TYPE_REAL
    beq DN
:   jsr typeErrIncompatible

DN: jsr popA
    jsr popQ
    rts
.endproc
