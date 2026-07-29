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

isLibraryOffset = 0
isRtnPtrOffset = isLibraryOffset + 1
rtnTypeOffset = isRtnPtrOffset + 1
symPtrOffset = rtnTypeOffset + 4
exprPtrOffset = symPtrOffset + 4

.export icodeSubroutineCall

.import icodeLibrarySubroutineCall, icodeDeclaredSubroutineCall, icodeStdRoutineCall
.import loadStackValue

; Call expression passed in Q
.proc icodeSubroutineCall
    stq ptr1
    jsr pushQ               ; exprPtr
    jsr pushQZero           ; symPtr
    jsr pushQZero           ; rtnType
    lda #0
    jsr pushA               ; isRtnPtr
    lda #0
    jsr pushA               ; isLibrary

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
    stq ptr1
    ldz #symPtrOffset
    jsr storePtr
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #rtnTypeOffset
    jsr storePtr
    ldq ptr1
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
    ldz #rtnTypeOffset
    jsr storePtr
    lda #1
    ldz #isRtnPtrOffset
    nop
    sta (stackPointer),z

:   ldz #symPtrOffset
    jsr loadStackValue
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
    ldz #isLibraryOffset
    nop
    sta (stackPointer),z

:   ldz #isLibraryOffset
    nop
    lda (stackPointer),z
    beq NL

    ; Library routine call
LL: ldz #exprPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #symPtrOffset
    jsr loadStackValue
    stq ptr2
    ldz #rtnTypeOffset
    jsr loadStackValue
    stq ptr3
    ldz #isRtnPtrOffset
    nop
    lda (stackPointer),z
    sta tmp1
    ldq ptr1
    jsr pushQ
    ldq ptr2
    jsr pushQ
    ldq ptr3
    jsr pushQ
    lda tmp1
    jsr pushA
    jsr icodeLibrarySubroutineCall
    jmp DN

    ; Not a library call
NL: ldz #rtnTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::flags
    nop
    lda (ptr1),z
    and #TYPE_FLAG_ISSTD
    bne ST
    ldz #exprPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #symPtrOffset
    jsr loadStackValue
    stq ptr2
    ldz #rtnTypeOffset
    jsr loadStackValue
    stq ptr3
    ldz #isRtnPtrOffset
    nop
    lda (stackPointer),z
    sta tmp1
    ldq ptr1
    jsr pushQ               ; expression ptr
    ldq ptr2
    jsr pushQ               ; symbol ptr
    ldq ptr3
    jsr pushQ               ; routine type ptr
    lda tmp1
    jsr pushA               ; isRtnPtr
    jsr icodeDeclaredSubroutineCall
    bra DN

    ; Standard routine call
ST: ldz #rtnTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #exprPtrOffset
    jsr loadStackValue
    stq ptr2
    ldz #type::routineCode
    nop
    lda (ptr1),z
    jsr pushA
    ldq ptr2
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    jsr icodeStdRoutineCall

DN: jsr popA            ; isLibrary
    jsr popA            ; isRtnPtr
    jsr popQ            ; rtnType
    jsr popQ            ; symPtr
    jsr popQ            ; exprPtr
    rts
.endproc

; Pointer passed in Q
; Stack offset passed in Z
.proc storePtr
    phz
    ldz #0
    stq ptr4
    plz
    ldx #0
:   lda ptr4,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    rts
.endproc
