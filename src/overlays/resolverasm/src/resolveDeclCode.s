;
; resolveDeclCode.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; resolveDeclCode routine

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

declOffset = 10

.export resolveDeclCode

.import getTypePtr, paramListResolve, stmtResolve

.bss

codePtr: .res 4

.code

.proc resolveDeclCode
    stq codePtr
    jsr scopeEnter
    jsr getTypePtr
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_PROGRAM
    beq :+
    ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr1),z
    jsr paramListResolve
:   ldq codePtr
    stq ptr1
    ldz #decl::code
    neg
    neg
    nop
    lda (ptr1),z
    jsr stmtResolve
    jsr scopeExit
    stq ptr2
    ldz #declOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #decl::symtab
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inx
    inz
    cpx #4
    bne :-
    rts
.endproc
