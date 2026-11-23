;
; typecheck.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; resolver overlay miscellaneous routines

.include "asmlib.inc"
.include "error.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export currentLineNumber, typeCheckError, loadStackValue, calcNamePtr, typeCheckWarning
.export typeErrIncompatible, typeErrInvalidType, typeErrParamCount
.export loadQPtr1, loadQPtr2, loadQPtr3, loadQPtr4, followPtr1
.export calcTypeBlockAddr

.bss

currentLineNumber: .res 2

.code

; The common errors, so a caller needs only a JSR.
.proc typeErrParamCount
    lda #errWrongNumberOfParams
    bra typeCheckError
.endproc

.proc typeErrInvalidType
    lda #errInvalidType
    bra typeCheckError
.endproc

; Falls into typeCheckError
.proc typeErrIncompatible
    lda #errIncompatibleTypes
.endproc

.proc typeCheckError
    ldx currentLineNumber
    ldy currentLineNumber+1
    jmp compilerError
.endproc

.proc typeCheckWarning
    ldx currentLineNumber
    ldy currentLineNumber+1
    jmp compilerWarning
.endproc

; This routine loads a pointer from the stack and leaves it in Q.
; Stack offset passed in Z.
.proc loadStackValue
    neg
    neg
    nop
    lda (stackPointer),z
    rts
.endproc

; Structure pointer in A/X/Y and structure offset in Z.
; Address returned in Q.
.proc calcNamePtr
    stz intOp32
    ldz #0
    stz intOp32+1
    stz intOp32+2
    stz intOp32+3
    clc
    adcq intOp32
    rts
.endproc

; These load Q from a pointer plus the offset in Z, which they keep.
; Flags are as the load left them.
.proc loadQPtr1
    neg
    neg
    nop
    lda (ptr1),z
    rts
.endproc

.proc loadQPtr2
    neg
    neg
    nop
    lda (ptr2),z
    rts
.endproc

.proc loadQPtr3
    neg
    neg
    nop
    lda (ptr3),z
    rts
.endproc

.proc loadQPtr4
    neg
    neg
    nop
    lda (ptr4),z
    rts
.endproc

; Follows the pointer at ptr1 plus Z: loads Q from it and stores it in ptr1.
.proc followPtr1
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    rts
.endproc

; Stack offset in A. The stack's address plus it is returned in Q.
.proc calcTypeBlockAddr
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq stackPointer
    clc
    adcq intOp32
    rts
.endproc
