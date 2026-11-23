;
; checkReadWriteCall.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Type checks the arguments of Read, Readln, ReadStr (after its source),
; Write, Writeln and WriteStr. Both checkers use the same stack frame, so
; they share the checks of arrays, records, files and the file's type.
; Write's frame must be on the stack, since a WriteStr call in an argument
; checks Write again.

.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "symtab.inc"
.include "zeropage.inc"
.include "4510macros.inc"

; The frame, from the top of the stack. The caller pushes the argument list
; and the routine code (rc*); rwBegin pushes the rest.
typeOffset = 0                  ; The argument's type, from exprTypeCheck
firstOffset = typeOffset + .sizeof(type)    ; Non-zero for the first argument
exprTypeOffset = firstOffset + 1            ; The argument's base type
fileTypeSubOffset = exprTypeOffset + 4      ; The typed file's base subtype
routineCodeOffset = fileTypeSubOffset + .sizeof(type)
argOffset = routineCodeOffset + 1           ; The current EXPR_ARG node

.export checkReadReadlnCall, checkWriteWritelnCall

.import typeCheckError, loadStackValue, exprTypeCheck, checkIntegerBaseType
.import checkArraysSameType, isAssignmentCompatible, isTypeInteger
.import calcTypeBlockAddr, followPtr1, loadQPtr1, loadQPtr2, loadQPtr3
.import typeErrIncompatible

.bss

; Read isn't checked again while it checks an argument, so these can be
; here and not in the frame.
exprLeft: .res 4
subscript: .res 1

.code

.proc checkReadReadlnCall
    jsr rwBegin

    ; Loop through the arguments
L1: ldz #argOffset
    jsr loadStackValue
    jsr isQZero
    bne :+
    jmp rwEnd

:   stq ptr1
    ldz #expr::left
    jsr loadQPtr1
    stq exprLeft
    jsr rwEvalArg

    lda #0
    sta subscript
    ldq exprLeft
    stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_SUBSCRIPT
    bne :+
    ldz #expr::left
    jsr followPtr1
    stq exprLeft
    lda #1
    sta subscript
    ldz #expr::kind
    nop
    lda (ptr1),z
:   cmp #EXPR_POINTER
    bne :+
    ldz #expr::left
    jsr followPtr1
    stq exprLeft
    lda #1
    sta subscript
    ldz #expr::kind
    nop
    lda (ptr1),z
:   cmp #EXPR_NAME
    beq :+
    lda #errInvalidVarParm
    jsr typeCheckError
    jmp NX
:   ldz #expr::name
    jsr loadQPtr1
    stq ptr4
    jsr scopeLookup
    stq ptr2
    jsr isQZero
    bne :+
    lda #errUndefinedIdentifier
    jsr typeCheckError
    bra NX
    ; An array element or what a pointer points to has the type that
    ; exprTypeCheck gave it. A variable has its symbol's type: an
    ; expression's type has a subtype even for an untyped file.
:   lda subscript
    beq :+
    ldz #exprTypeOffset
    jsr loadStackValue
    stq ptr1
    bra L3
:   ldz #symbol::type
    jsr loadQPtr2
    jsr getBaseType
    jsr storeExprType
L3: ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ARRAY
    bne :+
    jsr rwCheckArray
    bra NX
:   cmp #TYPE_RECORD
    bne :+
    jsr rwCheckRecord
    bra NX
:   cmp #TYPE_FILE
    bne :+
    jsr rwCheckFile
    bra NX
:   cmp #TYPE_TEXT
    bne :+
    jsr rwCheckText
    bra NX
:   jsr isTypeInteger
    beq IC
    cmp #TYPE_BOOLEAN
    beq IC
    cmp #TYPE_CHARACTER
    beq IC
    cmp #TYPE_STRING_VAR
    beq IC
    cmp #TYPE_REAL
    beq IC
ER: jsr typeErrIncompatible
    bra NX
    ; A constant can't be read into. ptr1 is still the base type.
IC: ldz #type::flags
    nop
    lda (ptr1),z
    and #TYPE_FLAG_ISCONST
    bne ER

NX: jsr rwNextArg
    jmp L1
.endproc

.proc checkWriteWritelnCall
    jsr rwBegin

    ; Loop through the arguments
L1: ldz #argOffset
    jsr loadStackValue
    jsr isQZero
    bne :+
    jmp rwEnd

:   stq ptr1
    ldz #expr::left
    jsr loadQPtr1
    jsr rwEvalArg
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ARRAY
    bne :+
    jsr rwCheckArray
    ; An array written to a file has no width
    ldz #fileTypeSubOffset
    nop
    lda (stackPointer),z
    bne NX
    bra WP
:   cmp #TYPE_RECORD
    bne :+
    jsr rwCheckRecord
    bra NX
:   cmp #TYPE_FILE
    bne :+
    jsr rwCheckFile
    bra NX
:   cmp #TYPE_TEXT
    bne :+
    jsr rwCheckText
    bra NX
:   jsr isTypeInteger
    beq WP
    cmp #TYPE_REAL
    beq WP
    cmp #TYPE_CHARACTER
    beq WP
    cmp #TYPE_BOOLEAN
    beq WP
    cmp #TYPE_STRING_LITERAL
    beq WP
    cmp #TYPE_STRING_VAR
    beq WP
    cmp #TYPE_STRING_OBJ
    beq WP
    jsr typeErrIncompatible
    bra NX
WP: jsr checkWidthAndPrecision

NX: jsr rwNextArg
    jmp L1
.endproc

; Pushes the frame above the caller's routine code and argument list.
.proc rwBegin
    lda #.sizeof(type)
    jsr pushBlock               ; fileTypeSub
    jsr pushQZero               ; exprType
    lda #1
    jsr pushA                   ; first
    lda #.sizeof(type)
    jsr pushBlock               ; type

    lda #0
    ldz #fileTypeSubOffset + type::kind
    nop
    sta (stackPointer),z
    rts
.endproc

; Pops the frame and the caller's routine code and argument list.
.proc rwEnd
    lda #.sizeof(type)
    jsr popBlock                ; type
    jsr popA                    ; first
    jsr popQ                    ; exprType
    lda #.sizeof(type)
    jsr popBlock                ; fileTypeSub
    jsr popA                    ; routine code
    jmp popQ                    ; argument list
.endproc

; Type checks the argument expression in Q into the frame's type, then
; falls into storeExprType with its base type.
.proc rwEvalArg
    stq ptr2
    ldq stackPointer
    stq ptr1
    ldq ptr2
    jsr pushQ                   ; expression
    jsr pushQZero               ; record symbol table
    ldq ptr1
    jsr pushQ                   ; type
    lda #0
    jsr pushA                   ; parentIsFuncCall
    jsr exprTypeCheck
    ldq stackPointer
    jsr getBaseType
.endproc

; Stores the type in Q in the frame's exprType and leaves it in ptr1.
.proc storeExprType
    stq ptr1
    ldz #exprTypeOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    rts
.endproc

; An array must be of Char, or with a typed file, of the file's type.
.proc rwCheckArray
    ldz #exprTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::subtype
    jsr loadQPtr1
    jsr getBaseType
    stq ptr1
    ldz #fileTypeSubOffset
    nop
    lda (stackPointer),z
    beq L1
    lda #fileTypeSubOffset
    jsr calcTypeBlockAddr
    stq ptr2
    ldz #exprTypeOffset
    jsr loadStackValue
    jsr pushQ
    ldq ptr2
    jsr pushQ
    jmp checkArraysSameType
L1: ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_CHARACTER
    bne ER
    rts
ER: jmp typeErrIncompatible
.endproc

; A record can only be read from or written to a file of its record type.
; The record's table is in the subtype of the type exprTypeCheck gave the
; argument. Read's exprType for a variable is its symbol's type, which
; doesn't have one.
.proc rwCheckRecord
    ldz #fileTypeSubOffset
    nop
    lda (stackPointer),z
    beq ER
    ldq stackPointer            ; The frame's type, at typeOffset
    jsr getBaseType
    stq ptr1
    ldz #type::subtype
    jsr followPtr1
    ldz #type::symtab
    jsr loadQPtr1
    stq ptr2
    lda #fileTypeSubOffset
    jsr calcTypeBlockAddr
    stq ptr3
    ldz #type::symtab
    jsr loadQPtr3
    stq ptr3
    ldx #0
:   lda ptr2,x
    cmp ptr3,x
    bne ER
    inx
    cpx #4
    bne :-
    rts
ER: jmp typeErrIncompatible
.endproc

; A file must be the first argument, and only Read and Write take a typed
; file. A typed file's base subtype is copied to fileTypeSub, for the
; arguments after it.
.proc rwCheckFile
    ldz #firstOffset
    nop
    lda (stackPointer),z
    bne :+
    jsr typeErrIncompatible
:   ldz #routineCodeOffset
    nop
    lda (stackPointer),z
    cmp #rcRead
    beq :+
    cmp #rcWrite
    beq :+
    jsr typeErrIncompatible
:   ldz #exprTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::subtype
    jsr loadQPtr1
    jsr isQZero
    beq DN
    jsr getBaseType
    stq ptr1
    lda #fileTypeSubOffset
    jsr calcTypeBlockAddr
    stq ptr2
    ldz #0
:   nop
    lda (ptr1),z
    nop
    sta (ptr2),z
    inz
    cpz #.sizeof(type)
    bne :-
DN: rts
.endproc

; A Text file must be the first argument. ReadStr and WriteStr take none:
; they read from and write to a string.
.proc rwCheckText
    ldz #firstOffset
    nop
    lda (stackPointer),z
    beq ER
    ldz #routineCodeOffset
    nop
    lda (stackPointer),z
    cmp #rcReadStr
    beq ER
    cmp #rcWriteStr
    bne :+
ER: jmp typeErrIncompatible
:   rts
.endproc

; After the first argument, an argument must be compatible with a typed
; file's subtype. rwCheckArray and rwCheckRecord checked arrays and
; records. Then moves to the next argument.
.proc rwNextArg
    ldz #firstOffset
    nop
    lda (stackPointer),z
    bne NA
    ldz #fileTypeSubOffset
    nop
    lda (stackPointer),z
    beq NA
    cmp #TYPE_ARRAY
    beq NA
    ldz #exprTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_RECORD
    beq NA
    ldz #fileTypeSubOffset
    nop
    lda (stackPointer),z
    jsr pushA
    ldq ptr1
    jsr pushQ
    jsr pushQZero
    jsr isAssignmentCompatible
    beq NA
    jsr typeErrIncompatible

NA: lda #0
    ldz #firstOffset
    nop
    sta (stackPointer),z
    ldz #argOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::right
    jsr followPtr1
    ldz #argOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    rts
.endproc

; This routine checks the field width and precision expressions of the
; current argument (the EXPR_ARG node at argOffset). Each one is optional.
; If present, it can be an expression of any integer type.
.proc checkWidthAndPrecision
    ldz #argOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::width
    jsr loadQPtr1
    jsr pushQ
    jsr checkIntegerBaseType
    ldz #argOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::precision
    jsr loadQPtr1
    jsr pushQ
    jmp checkIntegerBaseType
.endproc
