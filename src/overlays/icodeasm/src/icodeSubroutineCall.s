;
; icodeSubroutineCall.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export icodeSubroutineCall

.import icodeLibrarySubroutineCall, icodeDeclaredSubroutineCall, icodeStdRoutineCall

.bss

exprPtr: .res 4
symPtr: .res 4
rtnType: .res 4
isRtnPtr: .res 1
isLibrary: .res 1

.code

; Call expression passed in Q
.proc icodeSubroutineCall
    stq ptr1
    stq exprPtr

    lda #0
    sta isRtnPtr
    sta isLibrary

    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #expr::node
    neg
    neg
    nop
    lda (ptr1),z
    stq symPtr                  ; save this for later
    stq ptr1
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr1),z
    stq rtnType                 ; save this for later
    jsr getBaseType
    stq ptr1

    ; If the type is a routine pointer, get the subtype
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ROUTINE_POINTER
    bne :+
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    stq rtnType
    lda #1
    sta isRtnPtr

:   ldq symPtr
    stq ptr1
    ldz #symbol::decl
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    stq ptr1
    ldz #decl::isLibrary
    nop
    lda (ptr1),z
    sta isLibrary

:   lda isLibrary
    beq NL

    ; Library routine call
LL: ldq exprPtr
    jsr pushQ
    ldq symPtr
    jsr pushQ
    ldq rtnType
    jsr pushQ
    lda isRtnPtr
    jsr pushA
    jsr icodeLibrarySubroutineCall
    rts

    ; Not a library call
NL: ldq rtnType
    stq ptr1
    ldz #type::flags
    nop
    lda (ptr1),z
    and #TYPE_FLAG_ISSTD
    bne ST
    ldq exprPtr
    jsr pushQ
    ldq symPtr
    jsr pushQ
    ldq rtnType
    jsr pushQ
    lda isRtnPtr
    jsr pushA
    jsr icodeDeclaredSubroutineCall
    rts

    ; Standard routine call
ST: ldq rtnType
    stq ptr1
    ldz #type::routineCode
    nop
    lda (ptr1),z
    jsr pushA
    ldq exprPtr
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    jsr icodeStdRoutineCall
    rts
.endproc
