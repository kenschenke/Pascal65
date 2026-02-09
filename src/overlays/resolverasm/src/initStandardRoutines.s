;
; initStandardRoutines.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; freeUnits routine

.include "ast.inc"
.include "asmlib.inc"
.include "symtab.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export initStandardRoutines

.data

strAbs: .asciiz "abs"
strDec: .asciiz "dec"
strEoln: .asciiz "eoln"
strInc: .asciiz "inc"
strOrd: .asciiz "ord"
strPred: .asciiz "pred"
strRead: .asciiz "read"
strReadln: .asciiz "readln"
strReadstr: .asciiz "readstr"
strRound: .asciiz "round"
strSqr: .asciiz "sqr"
strSucc: .asciiz "succ"
strTrunc: .asciiz "trunc"
strWrite: .asciiz "write"
strWriteln: .asciiz "writeln"
strWritestr: .asciiz "writestr"

; These are in a specific order to create a balanced binary tree
; when entered in this order.
stdRtnList: .byte rcReadln, TYPE_PROCEDURE, .lobyte(strReadln), .hibyte(strReadln)
            .byte rcInc, TYPE_PROCEDURE, .lobyte(strInc), .hibyte(strInc)
            .byte rcDec, TYPE_PROCEDURE, .lobyte(strDec), .hibyte(strDec)
            .byte rcPred, TYPE_FUNCTION, .lobyte(strPred), .hibyte(strPred)
            .byte rcAbs, TYPE_FUNCTION, .lobyte(strAbs), .hibyte(strAbs)
            .byte rcEoln, TYPE_FUNCTION, .lobyte(strEoln), .hibyte(strEoln)
            .byte rcOrd, TYPE_FUNCTION, .lobyte(strOrd), .hibyte(strOrd)
            .byte rcRead, TYPE_PROCEDURE, .lobyte(strRead), .hibyte(strRead)
            .byte rcSucc, TYPE_FUNCTION, .lobyte(strSucc), .hibyte(strSucc)
            .byte rcRound, TYPE_FUNCTION, .lobyte(strRound), .hibyte(strRound)
            .byte rcWriteln, TYPE_PROCEDURE, .lobyte(strWriteln), .hibyte(strWriteln)
            .byte rcReadStr, TYPE_PROCEDURE, .lobyte(strReadstr), .hibyte(strReadstr)
            .byte rcSqr, TYPE_FUNCTION, .lobyte(strSqr), .hibyte(strSqr)
            .byte rcTrunc, TYPE_FUNCTION, .lobyte(strTrunc), .hibyte(strTrunc)
            .byte rcWrite, TYPE_PROCEDURE, .lobyte(strWrite), .hibyte(strWrite)
            .byte rcWriteStr, TYPE_FUNCTION, .lobyte(strWritestr), .hibyte(strWritestr)
            .byte 0

.bss

stdRtnListNdx: .res 1

.code

; This routine adds the standard routines to the global symbol table
.proc initStandardRoutines
    lda #0
    sta stdRtnListNdx

L1: ldx stdRtnListNdx
    lda stdRtnList,x
    bne :+
    rts

:   inx
    lda stdRtnList,x
    jsr pushA
    lda #0
    jsr pushA
    jsr pushQZero
    jsr pushQZero
    jsr typeCreate
    stq ptr1
    ldz #type::flags
    nop
    lda (ptr1),z
    ora #TYPE_FLAG_ISSTD
    nop
    sta (ptr1),z
    ldx stdRtnListNdx
    lda stdRtnList,x
    ldz #type::routineCode
    nop
    sta (ptr1),z
    lda #SYMBOL_GLOBAL
    jsr pushA
    ldq ptr1
    jsr pushQ
    jsr getCurrentRtnName
    jsr pushQ
    jsr symbolCreate
    stq ptr3
    jsr getCurrentRtnName
    stq ptr2
    clc
    jsr scopeBind

    ; Go to the next routine in the list.
    lda stdRtnListNdx
    clc
    adc #4
    sta stdRtnListNdx
    bra L1
.endproc

; This routine gets the current standard routine name and returns it in Q
.proc getCurrentRtnName
    ldx stdRtnListNdx
    inx
    inx
    lda stdRtnList,x
    pha
    inx
    lda stdRtnList,x
    tax
    pla
    ldy #0
    ldz #0
    rts
.endproc
