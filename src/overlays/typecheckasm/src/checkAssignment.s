;
; checkAssignment.s
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

leftTypeOffset = 12
rightTypeOffset = 8
resultTypeOffset = 4
exprRightOffset = 0

.export checkAssignment

.import loadStackValue, isTypeInteger, isAssignableToString
.import getTypeSize, typeCheckError, checkForwardVsFormalDeclaration
.import isAssignmentCompatible

.bss

isSubscript: .res 1
ptrKind: .res 1         ; kind of what the left pointer points to
ptrSymtab: .res 4       ; its symbol table, if it's a record

.code

.proc checkAssignment
    ; If the left type is a real and the right type is a real or integer,
    ; the result type is a real.
    ldz #leftTypeOffset
    jsr typeKind
    cmp #TYPE_REAL
    bne LC
    ldz #rightTypeOffset
    jsr typeKind
    cmp #TYPE_REAL
    beq LC
    jsr isTypeInteger
    bne LC                  ; Branch if not an integer
LR: lda #TYPE_REAL
    jsr setResultKind
    lda #4
    ldx #0
    jsr setResultSize
    jmp DN

    ; If the left and right types are a character, result is a character
LC: ldz #leftTypeOffset
    jsr typeKind
    cmp #TYPE_CHARACTER
    bne LB
    ldz #rightTypeOffset
    jsr typeKind
    cmp #TYPE_CHARACTER
    bne LB
    jsr setResultKind
    lda #1
    ldx #0
    jsr setResultSize
    jmp DN

    ; If the left and right types are boolean, result is a boolean
LB: ldz #leftTypeOffset
    jsr typeKind
    cmp #TYPE_BOOLEAN
    bne SV
    ldz #rightTypeOffset
    jsr typeKind
    cmp #TYPE_BOOLEAN
    bne SV
    jsr setResultKind
    lda #1
    ldx #0
    jsr setResultSize
    jmp DN

    ; If the left is a string variable, make sure the right is
    ; assignable to a string.
SV: ldz #leftTypeOffset
    jsr typeKind
    cmp #TYPE_STRING_VAR
    bne IC
    ldz #rightTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    ldz #rightTypeOffset
    jsr typeKind
    jsr pushA
    ldq ptr2
    jsr pushQ
    jsr isAssignableToString
    beq :+
    lda #errIncompatibleAssignment
    jsr typeCheckError
    lda #TYPE_VOID
    jsr setResultKind
    jmp DN
:   ldz #rightTypeOffset
    jsr typeKind
    jsr setResultKind
    lda #2
    ldx #0
    jsr setResultSize
    jmp DN

    ; A pointer assigned a pointer must point to the same type
IC: ldz #leftTypeOffset
    jsr typeKind
    cmp #TYPE_POINTER
    bne IA
    ldz #rightTypeOffset
    jsr typeKind
    cmp #TYPE_POINTER
    bne IA
    jsr checkPointerToPointer
    jmp DN

    ; Check if the assignment is compatible
IA: ldz #rightTypeOffset
    jsr loadStackValue
    stq ptr2
    ldz #exprRightOffset
    jsr loadStackValue
    stq ptr3
    ldz #leftTypeOffset
    jsr typeKind
    jsr pushA
    ldq ptr2
    jsr pushQ
    ldq ptr3
    jsr pushQ
    jsr isAssignmentCompatible
    bne EN
    ldz #leftTypeOffset
    jsr typeKind
    pha
    jsr setResultKind
    pla
    jsr getTypeSize
    jsr setResultSize
    jmp DN

    ; If this is an enumeration, check the assignment
EN: ldz #leftTypeOffset
    jsr typeKind
    cmp #TYPE_ENUMERATION
    bne PT
    ldz #rightTypeOffset
    jsr typeKind
    cmp #TYPE_ENUMERATION
    beq :+
    cmp #TYPE_ENUMERATION_VALUE
    bne PT
:   ; The paramFields must be the same
    ldz #leftTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #rightTypeOffset
    jsr loadStackValue
    stq ptr2
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    ldx #0
:   lda ptr1,x
    cmp ptr2,x
    bne EE
    inx
    cpx #4
    bne :-
EV: lda #TYPE_VOID
    jsr setResultKind
    jmp DN
EE: lda #errIncompatibleAssignment
    jsr typeCheckError
    bra EV

    ; Check pointer assignment
PT: ldz #leftTypeOffset
    jsr typeKind
    cmp #TYPE_POINTER
    bne RP
    ldz #exprRightOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_BYTE_LITERAL
    beq DN
    cmp #EXPR_WORD_LITERAL
    beq DN
    jsr checkPointerAssignment
    jmp DN

RP: ldz #leftTypeOffset
    jsr typeKind
    cmp #TYPE_ROUTINE_POINTER
    bne ER
    jsr checkRoutinePointerAssignment
    jmp DN

ER: lda #errIncompatibleAssignment
    jsr typeCheckError
    lda #TYPE_VOID
    jsr setResultKind

DN: jsr popQ
    jsr popQ
    jsr popQ
    jsr popQ
    rts
.endproc

; This routine returns the type kind in A for the left or right type.
; The left or right stack offset is passed in Z.
.proc typeKind
    ; If the stack offset is rightTypeOffset and the right expression is a type cast,
    ; then the kind should be evalTypeKind
    ; cpz #rightTypeOffset
    ; bne L1
    ; ldz #exprRightOffset
    ; jsr loadStackValue
    ; stq ptr1
    ; ldz #expr::kind
    ; nop
    ; lda (ptr1),z
    ; cmp #EXPR_CAST
    ; bne L1
    ; ldz #expr::evalTypeKind
    ; nop
    ; lda (ptr1),z
    ; brk
    ; rts

; L1:
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    rts
.endproc

; This routine sets the result kind.
; The kind is passed in A.
.proc setResultKind
    pha             ; Save the kind
    ldz #resultTypeOffset
    jsr loadStackValue
    stq ptr1
    pla
    ldz #type::kind
    nop
    sta (ptr1),z
    rts
.endproc

; This routine sets the result size.
; The size is passed in A/X.
.proc setResultSize
    pha             ; Save the size
    phx
    ldz #resultTypeOffset
    jsr loadStackValue
    stq ptr1
    plx
    pla
    ldz #type::size
    nop
    sta (ptr1),z
    txa
    inz
    nop
    sta (ptr1),z
    rts
.endproc

.proc checkPointerAssignment
    lda #0
    sta isSubscript     ; becomes non-zero if address of array subscript
    ldz #leftTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1            ; ptr1 is left subtype
    ldz #exprRightOffset
    jsr loadStackValue
    stq ptr2
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2            ; ptr2 is right expression's left child
    ldz #expr::kind
    nop
    lda (ptr2),z
    cmp #EXPR_SUBSCRIPT
    bne :+
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    lda #1
    sta isSubscript
:   ldz #expr::node
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr3            ; ptr3 is the symbol type
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr3
    ldq ptr1
    jsr getBaseType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr3),z
    cmp #TYPE_FUNCTION
    beq L1
    cmp #TYPE_ROUTINE_POINTER
    bne L2
L1: ldz #type::subtype
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr3
L2: ldz #type::kind
    nop
    lda (ptr3),z
    cmp #TYPE_ARRAY
    bne :+
    lda isSubscript
    beq :+
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr3
:   ldz #type::kind
    nop
    lda (ptr3),z
    cmp #TYPE_POINTER
    bne :+
    ; Assignment okay
    jmp DN
    ; The kinds of the base types must match, and a record must be the
    ; same record. getBaseType changes ptr1, so keep the pointer's target
    ; kind and table in ptrKind and ptrSymtab.
:   ldz #type::kind
    nop
    lda (ptr1),z
    sta ptrKind
    ldz #type::symtab
    neg
    neg
    nop
    lda (ptr1),z
    stq ptrSymtab
    ldq ptr3
    jsr getBaseType
    stq ptr3
    lda ptrKind
    ldz #type::kind
    nop
    cmp (ptr3),z
    bne ER
    cmp #TYPE_RECORD
    bne DN
    ldz #type::symtab
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr3
    ldx #0
:   lda ptrSymtab,x
    cmp ptr3,x
    bne ER
    inx
    cpx #4
    bne :-
    bra DN
ER:
    lda #errIncompatibleAssignment
    jsr typeCheckError
DN: rts
.endproc

; This routine checks the assignment of a pointer to a pointer. The base
; types they point to must be the same kind, and a record the same record
; (the same symbol table). getBaseType changes the pointers, so the left
; one's kind and table are kept in ptrKind and ptrSymtab.
.proc checkPointerToPointer
    ldz #leftTypeOffset
    jsr loadPointerTarget
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    sta ptrKind
    ldz #type::symtab
    neg
    neg
    nop
    lda (ptr1),z
    stq ptrSymtab
    ldz #rightTypeOffset
    jsr loadPointerTarget
    stq ptr1
    lda ptrKind
    ldz #type::kind
    nop
    cmp (ptr1),z
    bne ER
    cmp #TYPE_RECORD
    bne OK
    ldz #type::symtab
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldx #0
:   lda ptrSymtab,x
    cmp ptr1,x
    bne ER
    inx
    cpx #4
    bne :-
OK: lda #TYPE_POINTER
    jsr setResultKind
    lda #TYPE_POINTER
    jsr getTypeSize
    jmp setResultSize
ER: lda #errIncompatibleAssignment
    jsr typeCheckError
    lda #TYPE_VOID
    jmp setResultKind
.endproc

; This routine returns the base type that the pointer type at the stack
; offset in Z points to.
.proc loadPointerTarget
    jsr loadStackValue
    stq ptr1
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jmp getBaseType
.endproc

.proc checkRoutinePointerAssignment
    ldz #rightTypeOffset
    jsr typeKind
    cmp #TYPE_ROUTINE_ADDRESS
    beq :+
    lda #errIncompatibleAssignment
    jsr typeCheckError

:   ldz #exprRightOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #expr::name
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr4
    jsr scopeLookup
    stq ptr2
    jsr pushQ
    ldz #symbol::decl
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr1
    ldz #decl::isLibrary
    nop
    lda (ptr1),z
    beq :+
    lda #errIncompatibleAssignment
    jsr typeCheckError
:   jsr popQ
    stq ptr2                ; ptr2 is the symbol
    ldz #leftTypeOffset
    jsr loadStackValue
    stq ptr1                ; ptr1 is the left type
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    ; Make sure the routine pointer is the same type as the routine it points to
    ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr2),z
    jsr pushQ
    jsr checkForwardVsFormalDeclaration
    rts
.endproc
