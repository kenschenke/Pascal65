;
; checkReadStrCall.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "symtab.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export checkReadStrCall

.import typeCheckError, exprTypeCheck, checkReadReadlnCall
.import isAssignableToString
.import loadQPtr1, loadStackValue, typeErrIncompatible, typeErrParamCount

.bss

argPtr: .res 4

.code

; This routine checks a call to ReadStr(str, ...). The first argument
; is anything that can be assigned to a string. The rest are checked
; like Read's arguments.
; Argument list passed in Q
.proc checkReadStrCall
    jsr isQZero
    bne :+
    jmp typeErrParamCount
:   stq argPtr

    ; Evaluate the first argument's type into a zeroed type block
    lda #.sizeof(type)
    jsr pushBlock
    lda #0
    taz
:   nop
    sta (stackPointer),z
    inz
    cpz #.sizeof(type)
    bne :-
    ; Check the EXPR_ARG, as routine calls do. It sets the arg's
    ; evalType, and evaluates a function call in the argument correctly.
    ldq stackPointer
    stq ptr2
    ldq argPtr
    jsr pushQ
    jsr pushQZero
    ldq ptr2
    jsr pushQ
    lda #0
    jsr pushA
    jsr exprTypeCheck

    ; Is it assignable to a string? For an array, isAssignableToString
    ; looks at the element type.
    ldq stackPointer
    jsr getBaseType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    pha
    cmp #TYPE_ARRAY
    bne L1
    ldz #type::subtype
    jsr loadQPtr1
    jsr getBaseType
    stq ptr1
L1:
    pla
    jsr pushA
    ldq ptr1
    jsr pushQ
    jsr isAssignableToString
    beq :+
    jsr typeErrIncompatible

    ; Evaluating the argument can put a copy of a type name in the
    ; type block. Free it.
:   ldz #type::name
    jsr loadStackValue
    jsr isQZero
    beq :+
    jsr heapFree
:   lda #.sizeof(type)
    jsr popBlock

    ; Check the variables to read into
    ldq argPtr
    stq ptr1
    ldz #expr::right
    jsr loadQPtr1
    jsr isQZero
    beq DN
    jsr pushQ
    lda #rcReadStr
    jsr pushA
    jsr checkReadReadlnCall
DN: rts
.endproc
