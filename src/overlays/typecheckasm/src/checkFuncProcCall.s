;
; checkFuncProcCall.s
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

argTypeOffset = 0           ; must be top of stack
argPtrOffset = argTypeOffset + .sizeof(type)
paramPtrOffset = argPtrOffset + 4
symTypeOffset = paramPtrOffset + 4
rtnTypePtrOffset = symTypeOffset + 4
exprOffset = rtnTypePtrOffset + 4

.export checkFuncProcCall, getRecordSymtab

.import typeCheckError, loadStackValue, checkStdRoutine, exprTypeCheck
.import getTypeConversion, checkArraysSameType, isTypeInteger
.import checkIntegerPrecisionWarning
.import checkForwardVsFormalDeclaration, isAssignableToString
.import isDynamicArray

.bss

paramKind: .res 1
argKind: .res 1
namePtr: .res 4
; Non-zero while checking a call to the System unit's Length.
; checkParams keeps it on the CPU stack around exprTypeCheck because
; an argument can contain another call.
isLibLength: .res 1
; Set by checkParams when isLibLength and the argument is an array.
isArrayLength: .res 1
; A parameter type's symbol table or subtype's kind, kept across getBaseType
paramSub: .res 4

.data

strLength: .asciiz "length"
strArrayLength: .asciiz "#length"

.code

; Parameters passed on the runtime stack, bottom to top:
;    Expression pointer to the first routine argument
;    Pointer to the return type
.proc checkFuncProcCall
    ; Push null pointers on the stack for the param and arg
    jsr pushQZero               ; symType
    jsr pushQZero               ; paramPtr
    jsr pushQZero               ; argPtr

    ; Add a type to the stack
    lda #.sizeof(type)
    jsr pushBlock

    ; Zero out the return type
    ldz #rtnTypePtrOffset
    jsr loadStackValue
    stq ptr1
    lda #0
    taz
:   nop
    sta (ptr1),z
    inz
    cpz #.sizeof(type)
    bne :-

    ; Zero out the argType
    lda #0
    taz
:   nop
    sta (stackPointer),z
    inz
    cpz #.sizeof(type)
    bne :-

    ; Make sure the routine name exists
    ldz #exprOffset
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
    stq namePtr
    jsr scopeLookup
    jsr isQZero
    bne :+
    lda #errUndefinedIdentifier
    jsr typeCheckError
    ldz #rtnTypePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    lda #TYPE_VOID
    nop
    sta (ptr1),z
    jmp DN

    ; If the symbol is the function's return value then look up the
    ; sumbol in the parent scope because the function's symbol is needed.
:   stq ptr1
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #symTypeOffset
    jsr storePtr
    ldq ptr1
    jsr getBaseType
    stq ptr1
    ldz #type::flags
    nop
    lda (ptr1),z
    and #TYPE_FLAG_ISRETVAL
    beq L1
    ldq namePtr
    stq ptr4
    jsr scopeLookupParent
    jsr isQZero
    bne :+
    lda #errUndefinedIdentifier
    jsr typeCheckError
    ldz #rtnTypePtrOffset
    jsr loadStackValue
    stq ptr1
    lda #TYPE_VOID
    nop
    sta (ptr1),z
    bra L1
:   stq ptr1
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #symTypeOffset
    jsr storePtr

    ; Is it a routine pointer?
L1: ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ROUTINE_POINTER
    bne :+
    ; It is - so get the subtype
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #symTypeOffset
    jsr storePtr
    
:   ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_FUNCTION
    beq :+
    cmp #TYPE_PROCEDURE
    beq :+
    ; It's not a function or procedure, so it has no parameters to check
    lda #errInvalidExpression
    jsr typeCheckError
    ldz #rtnTypePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    lda #TYPE_VOID
    nop
    sta (ptr1),z
    jmp DN

    ; Is this a standard routine?
:   ldz #type::flags
    nop
    lda (ptr1),z
    and #TYPE_FLAG_ISSTD
    beq :+
    ; It is a standard routine.
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #rtnTypePtrOffset
    jsr loadStackValue
    stq ptr2
    ldz #symTypeOffset
    jsr loadStackValue
    jsr pushQ                   ; routine type
    ldq ptr1
    jsr pushQ                   ; first argument
    ldq ptr2
    jsr pushQ                   ; return type
    jsr checkStdRoutine
    jmp DN

    ; Check the parameters
:   jsr checkLibLength
    bcc :+
    jmp DN                      ; wrong number of arguments for Length
:   jsr checkParams

    ; Was it Length with an array argument?
    lda isArrayLength
    beq :+
    jsr routeArrayLength
    jmp DN

    ; Is there a subtype (a function)?
:
    ldz #symTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq DN
    stq ptr1
    ldz #rtnTypePtrOffset
    jsr loadStackValue
    stq ptr2
    ldz #type::kind
    nop
    lda (ptr1),z
    nop
    sta (ptr2),z
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr3
    ldx #0
    ldz #type::subtype
:   lda ptr3,x
    nop
    sta (ptr2),z
    inz
    inx
    cpx #4
    bne :-
    ldq ptr2
    jsr pushQ
    ldz #type::name
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    jsr nameClone
:   stq ptr3
    jsr popQ
    stq ptr2
    ldx #0
    ldz #type::name
:   lda ptr3,x
    nop
    sta (ptr2),z
    inz
    inx
    cpx #4
    bne :-

DN: lda #.sizeof(type)
    jsr popBlock
    jsr popQ                ; argPtr
    jsr popQ                ; paramPtr
    jsr popQ                ; symType
    jsr popQ                ; returnType
    jsr popQ                ; exprPtr
    rts
.endproc

.proc checkParams
    ldz #symTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr1),z
    ldz #paramPtrOffset
    jsr storePtr
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    ldz #argPtrOffset
    jsr storePtr

L1: ldz #paramPtrOffset
    jsr loadStackValue
    jsr isQZero
    bne :+
    ldz #argPtrOffset
    jsr loadStackValue
    jsr isQZero
    bne :+
    jmp DN

    ; Clear the rightType
:   lda #0
    taz
:   nop
    sta (stackPointer),z
    inz
    cpz #.sizeof(type)
    bne :-

    ; Call exprTypeCheck for the argument
    ldz #argPtrOffset
    jsr loadStackValue
    stq ptr1
    ldq stackPointer
    stq ptr2
    ldq ptr1
    jsr pushQ
    jsr pushQZero
    ldq ptr2
    jsr pushQ
    lda #0
    jsr pushA
    lda isLibLength
    pha
    jsr exprTypeCheck
    pla
    sta isLibLength
    ; A call in the argument may have set it.
    lda #0
    sta isArrayLength

    ; Length of an array is checked as a standard routine
    lda isLibLength
    beq :+
    ldq stackPointer
    jsr getBaseType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ARRAY
    bne :+
    lda #1
    sta isArrayLength
    jmp NX

    ; Get the type of the routine parameter
:
    ldz #paramPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #param_list::type
    neg
    neg
    nop
    lda (ptr1),z
    jsr getBaseType
    stq ptr1

    ldz #type::kind
    nop
    lda (ptr1),z
    sta paramKind
    ldq stackPointer
    jsr getBaseType
    stq ptr2
    ldz #type::kind
    nop
    lda (ptr2),z
    sta argKind

    ; getBaseType changed ptr1. The checks below expect the parameter's
    ; base type in it.
    ldz #paramPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #param_list::type
    neg
    neg
    nop
    lda (ptr1),z
    jsr getBaseType
    stq ptr1

    ; if (paramType.kind == TYPE_ENUMERATION)
    lda paramKind
    cmp #TYPE_ENUMERATION
    bne :+
    lda argKind
    cmp #TYPE_ENUMERATION
    beq EN
    cmp #TYPE_ENUMERATION_VALUE
    bne :+
EN: jsr checkEnumerationParam
    jmp NX

    ; if (paramType.kind == TYPE_RECORD)
:   lda paramKind
    cmp #TYPE_RECORD
    bne :+
    lda argKind
    cmp #TYPE_RECORD
    bne :+
    jsr checkRecordParam
    jmp NX

    ; if (paramType.kind == TYPE_ARRAY)
:   lda paramKind
    cmp #TYPE_ARRAY
    bne :+
    lda argKind
    cmp #TYPE_ARRAY
    bne :+
    jsr checkDynamicParam
    bcc AR
    jmp NX
AR: ldz #paramPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #param_list::type
    neg
    neg
    nop
    lda (ptr1),z
    jsr getBaseType
    stq ptr1
    ldq stackPointer
    stq ptr2
    ldq ptr1
    jsr pushQ
    ldq ptr2
    jsr pushQ
    jsr checkArraysSameType
    jmp NX

    ; if (isTypeInteger(paramType.kind))
    ; A Var parameter's argument must be a variable of the same kind, which
    ; checkParamByRef checks.
:   lda paramKind
    jsr isTypeInteger
    bne :+
    lda argKind
    jsr isTypeInteger
    bne :+
    ldz #paramPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #param_list::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #type::flags
    nop
    lda (ptr1),z
    and #TYPE_FLAG_ISBYREF
    lbne BR
    jsr checkIntegerParam
    jmp NX

    ; if (paramType.kind == TYPE_STRING_VAR)
:   lda paramKind
    cmp #TYPE_STRING_VAR
    bne :+
    jsr checkStringVarParam
    jmp NX

    ; if (paramType.kind == TYPE_FILE)
:   lda paramKind
    cmp #TYPE_FILE
    bne :+
    jsr checkFileParam
    jmp NX

    ; if (paramType.kind == TYPE_POINTER &&
    ;     (argType.kind == TYPE_ADDRESS || argType.kind == TYPE_POINTER))
    ; checkParamByRef checks a Var parameter's argument after.
:   lda paramKind
    cmp #TYPE_POINTER
    bne :++
    lda argKind
    cmp #TYPE_ADDRESS
    beq :+
    cmp #TYPE_POINTER
    bne :++
:   jsr checkPointerParam
    jmp BR

    ; if (paramType.kind == TYPE_ROUTINE_POINTER && argType.kind == TYPE_ROUTINE_ADDRESS)
:   lda paramKind
    cmp #TYPE_ROUTINE_POINTER
    bne :+
    lda argKind
    cmp #TYPE_ROUTINE_ADDRESS
    bne :+
    jsr checkRoutinePointerParam
    jmp NX

    ; if (paramType.kind != argType.kind)
:   lda paramKind
    cmp argKind
    beq :+
    lda #errInvalidType
    jsr typeCheckError

:
BR: ldz #paramPtrOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #param_list::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #type::flags
    nop
    lda (ptr1),z
    and #TYPE_FLAG_ISBYREF
    beq NX
    jsr checkParamByRef

NX: ldz #paramPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #param_list::next
    neg
    neg
    nop
    lda (ptr1),z
    ldz #paramPtrOffset
    jsr storePtr
    ldz #argPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    ldz #argPtrOffset
    jsr storePtr
    ; If a subtype was allocated for the rightType of TYPE_ADDRESS, free it.
    ldz #type::kind
    nop
    lda (stackPointer),z
    cmp #TYPE_ADDRESS
    beq FR
    cmp #TYPE_ROUTINE_ADDRESS
    bne :+
FR: ldz #type::subtype
    neg
    neg
    nop
    lda (stackPointer),z
    jsr isQZero
    beq :+
    jsr freeType
    ; Free the copy of a type name the argument may have put in rightType
    ; (a dereferenced pointer to a named type does). L1 clears rightType.
:   ldz #type::name
    neg
    neg
    nop
    lda (stackPointer),z
    jsr isQZero
    beq :+
    jsr heapFree
:   jmp L1

DN: rts
.endproc

; This routine makes sure an array argument and an array parameter are
; both static or both dynamic. If not, it reports an error and returns
; with the carry set.
.proc checkDynamicParam
    ldz #paramPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #param_list::type
    neg
    neg
    nop
    lda (ptr1),z
    jsr isDynamicArray
    php
    ldq stackPointer
    jsr isDynamicArray
    beq L1
    ; The argument is static
    plp
    bne OK
    bra ER
    ; The argument is dynamic
L1: plp
    beq OK
ER: lda #errStaticDynArrayMismatch
    jsr typeCheckError
    sec
    rts
OK: clc
    rts
.endproc

.proc checkEnumerationParam
    ; Compare paramType with argType.
    ; Look up argType first
    ldz #paramPtrOffset
    jsr loadStackValue
    stq ptr3
    ldz #param_list::type
    neg
    neg
    nop
    lda (ptr3),z
    jsr getBaseType
    stq ptr3
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr3
    ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr3
    ldq stackPointer
    stq ptr4
    ldq ptr3
    jsr pushQ                       ; Save ptr3 on the stack
    ldq ptr4
    jsr getBaseType
    stq ptr4
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr4),z
    stq ptr4
    ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr4),z
    stq ptr4
    jsr popQ                        ; Pop ptr3 back off stack
    stq ptr3
    ldx #0
:   lda ptr3,x
    cmp ptr4,x
    bne :+
    inx
    cpx #4
    bne :-
    rts
:   lda #errInvalidType
    jsr typeCheckError
    rts
.endproc

; A record's fields are in its symbol table, so two record types are the
; same if they have the same table. ptr1 is the parameter's base type.
.proc checkRecordParam
    ; Compare paramType.symtab with argType's
    ldz #type::symtab
    neg
    neg
    nop
    lda (ptr1),z
    stq paramSub
    ldq stackPointer
    jsr getRecordSymtab
    stq ptr4
    ldx #0
:   lda paramSub,x
    cmp ptr4,x
    bne :+
    inx
    cpx #4
    bne :-
    rts
:   lda #errInvalidType
    jsr typeCheckError
    rts
.endproc

; This routine returns the symbol table of the record type in Q, or zero
; for a type that has none. An expression's type (see evalName) has no
; table of its own, but its subtype is the record type that has one.
.proc getRecordSymtab
    stq ptr4
    jsr pushQ                   ; pushQ doesn't keep Q
    ldq ptr4
    jsr getBaseType
    stq ptr4
    ldz #type::symtab
    neg
    neg
    nop
    lda (ptr4),z
    jsr isQZero
    bne DN
    ldz #0
    jsr loadStackValue          ; the type again
    stq ptr4
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr4),z
    jsr isQZero
    beq DN
    jsr getBaseType
    stq ptr4
    ldz #type::symtab
    neg
    neg
    nop
    lda (ptr4),z
DN: stq ptr4
    jsr popQ
    ldq ptr4
    rts
.endproc

.proc checkIntegerParam
    ldz #argPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    lda paramKind
    ldx argKind
    jsr checkIntegerPrecisionWarning
    rts
.endproc

; The Var flag is on the parameter's own type, not its base type.
.proc checkStringVarParam
    ldz #paramPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #param_list::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #type::flags
    nop
    lda (ptr1),z
    and #TYPE_FLAG_ISBYREF
    beq :+
    lda argKind
    cmp #TYPE_STRING_VAR
    beq :+
    lda #errInvalidType
    jsr typeCheckError
    jmp DN
:   ldz #type::subtype
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr2
    lda argKind
    jsr pushA
    ldq ptr2
    jsr pushQ
    jsr isAssignableToString
    beq DN
    lda #errInvalidType
    jsr typeCheckError
DN: rts
.endproc

; A file parameter is a Var parameter. A typed file's argument must be a
; file of the same kind of type. ptr1 is the parameter's base type.
.proc checkFileParam
    lda argKind
    cmp #TYPE_TEXT
    beq L3
    cmp #TYPE_FILE
    bne L1
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L2                      ; an untyped file takes any file
    jsr getBaseType
    stq ptr4
    ldz #type::kind
    nop
    lda (ptr4),z
    sta paramSub
    ; if (argType.subtype.kind != paramType.subtype.kind)
    ldq stackPointer
    jsr getBaseType
    stq ptr4
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr4),z
    jsr isQZero
    beq L1                      ; an untyped file
    jsr getBaseType
    stq ptr4
    lda paramSub
    ldz #type::kind
    nop
    cmp (ptr4),z
    beq L2
L1: lda #errInvalidType
    jsr typeCheckError
    ; if (!(paramType.flags & TYPE_FLAG_ISBYREF))
L2: ldz #paramPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #param_list::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #type::flags
    nop
    lda (ptr1),z
    and #TYPE_FLAG_ISBYREF
    bne L3
    lda #errInvalidType
    jsr typeCheckError
L3: rts
.endproc

; The base types of what the parameter and the argument (a pointer or an
; address) point to must be the same kind, and a record the same record
; (the same symbol table). ptr1 is the parameter's base type. The
; argument's type can be a type name, so its base type is looked up
; first. getBaseType changes ptr1, so the parameter's kind is kept on the
; stack and its table in paramSub.
.proc checkPointerParam
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jsr getBaseType
    stq ptr3
    ldz #type::symtab
    neg
    neg
    nop
    lda (ptr3),z
    stq paramSub
    ldz #type::kind
    nop
    lda (ptr3),z
    pha
    ldq stackPointer
    jsr getBaseType
    stq ptr4
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr4),z
    jsr getBaseType
    stq ptr4
    pla
    ldz #type::kind
    nop
    cmp (ptr4),z
    bne ER
    cmp #TYPE_RECORD
    bne DN
    ; What an address points to can be an expression's type, which has
    ; no table of its own (see getRecordSymtab)
    ldq stackPointer
    jsr getBaseType
    stq ptr4
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr4),z
    jsr getRecordSymtab
    stq ptr4
    ldx #0
:   lda paramSub,x
    cmp ptr4,x
    bne ER
    inx
    cpx #4
    bne :-
DN: rts
ER: lda #errIncompatibleTypes
    jsr typeCheckError
    rts
.endproc

.proc checkRoutinePointerParam
    ldz #paramPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #param_list::type
    neg
    neg
    nop
    lda (ptr1),z
    jsr getBaseType
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

    ldz #argPtrOffset
    jsr loadStackValue
    stq ptr2
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    ldz #expr::node
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    ldz #symbol::type
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
    ldq ptr1
    jsr pushQ
    ldq ptr2
    jsr pushQ
    jsr checkForwardVsFormalDeclaration
    rts
.endproc

.proc checkParamByRef
    ldz #argPtrOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr2
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2

    ; if (argType.kind == TYPE_TEXT && paramType.kind == TYPE_FILE)
    lda argKind
    cmp #TYPE_TEXT
    bne L1
    lda paramKind
    cmp #TYPE_FILE
    bne L1
    rts

L1: lda argKind
    cmp paramKind
    beq L2
    lda #errInvalidVarParm
    jsr typeCheckError
    rts

L2: ldz #expr::kind
    nop
    lda (ptr2),z
    cmp #EXPR_SUBSCRIPT
    beq L3
    cmp #EXPR_NAME
    beq L3
    cmp #EXPR_FIELD
    beq L3
    cmp #EXPR_POINTER
    beq L3
    lda #errInvalidVarParm
    jsr typeCheckError
    rts

L3: ldz #type::flags
    nop
    lda (stackPointer),z
    and #TYPE_FLAG_ISCONST
    beq :+
    lda #errInvalidVarParm
    jsr typeCheckError
:   rts
.endproc

; This routine looks for a call to the System unit's Length. It sets
; isLibLength if it is one and clears isArrayLength. Length takes one
; argument. If it has another number of them, this routine reports an
; error and returns with the carry set.
.proc checkLibLength
    lda #0
    sta isLibLength
    sta isArrayLength

    ; Is the routine's name "length"?
    ldq namePtr
    stq ptr1
    ldx #0
:   txa
    taz
    nop
    lda (ptr1),z
    cmp strLength,x
    bne NO
    inx
    cmp #0
    bne :-

    ; Is it a library routine?
    ldq namePtr
    stq ptr4
    jsr scopeLookup
    jsr isQZero
    beq NO
    stq ptr1
    ldz #symbol::decl
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq NO
    stq ptr1
    ldz #decl::isLibrary
    nop
    lda (ptr1),z
    beq NO
    lda #1
    sta isLibLength

    ; There must be exactly one argument
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq WN
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq NO
WN: lda #errWrongNumberOfParams
    jsr typeCheckError
    lda #0
    sta isLibLength
    ; Return its declared type so the caller doesn't report another error
    ldz #rtnTypePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    lda #TYPE_BYTE
    nop
    sta (ptr1),z
    sec
    rts

NO: clc
    rts
.endproc

; This routine finishes a call to Length with an array argument. Length
; returns an Integer and the call's routine becomes the standard routine
; for an array's length, so code generation treats it as one.
.proc routeArrayLength
    lda #0
    sta isArrayLength
    sta isLibLength

    ; The return type is an Integer
    ldz #rtnTypePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    lda #TYPE_INTEGER
    nop
    sta (ptr1),z
    ldz #type::size
    lda #2
    nop
    sta (ptr1),z
    inz
    lda #0
    nop
    sta (ptr1),z

    ; Point the routine name at the standard routine
    lda #<strArrayLength
    ldx #>strArrayLength
    ldy #0
    ldz #0
    stq ptr4
    jsr scopeLookup
    jsr isQZero
    beq DN
    stq ptr3
    ldz #exprOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #expr::node
    ldx #0
:   lda ptr3,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
DN: rts
.endproc

; This routine stores the 24-bit pointer in A/X/Y
; to the runtime stack at the offset in Z.
.proc storePtr
    phz
    ldz #0
    stq ptr2
    plz
    ldx #0
:   lda ptr2,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    rts
.endproc
