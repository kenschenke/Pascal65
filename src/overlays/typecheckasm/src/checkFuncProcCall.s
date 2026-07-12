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
rtnTypePtrOffset = paramPtrOffset + 4
exprOffset = rtnTypePtrOffset + 4

.export checkFuncProcCall

.import typeCheckError, loadStackValue, checkStdRoutine, exprTypeCheck
.import getTypeConversion, checkArraysSameType, isTypeInteger
.import checkForwardVsFormalDeclaration, isAssignableToString

.bss

symType: .res 4
paramKind: .res 1
argKind: .res 1
namePtr: .res 4

.code

; Parameters passed on the runtime stack, bottom to top:
;    Expression pointer to the first routine argument
;    Pointer to the return type
.proc checkFuncProcCall
    ; Push null pointers on the stack for the param and arg
    jsr pushQZero
    jsr pushQZero
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
    stq symType
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
    stq symType

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
    stq symType
    
:   ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_FUNCTION
    beq :+
    cmp #TYPE_PROCEDURE
    beq :+
    ; It's not a function or procedure
    lda #errInvalidExpression
    jsr typeCheckError
    ldz #rtnTypePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    lda #TYPE_VOID
    nop
    sta (ptr1),z
    ldq symType
    stq ptr1

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
    ldq symType                 ; routine type
    jsr pushQ
    ldq ptr1                    ; first argument
    jsr pushQ
    ldq ptr2                    ; return type
    jsr pushQ
    jsr checkStdRoutine
    bra DN

    ; Check the parameters
:   jsr checkParams

    ; Is there a subtype (a function)?
    ldq symType
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
    ldz #type::name
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr3
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
    jsr popQ
    jsr popQ
    jsr popQ
    jsr popQ
    rts
.endproc

.proc checkParams
    ldq symType
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

    ; Call exprTypeCheck for the argument
:   ldz #argPtrOffset
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
    jsr exprTypeCheck

    ; Get the type of the routine parameter
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
    ldq stackPointer
    stq ptr2
    ldq ptr1
    jsr pushQ
    ldq ptr2
    jsr pushQ
    jsr checkArraysSameType
    jmp NX

    ; if (isTypeInteger(paramType.kind))
:   lda paramKind
    jsr isTypeInteger
    bne :+
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

    ; if (paramType.kind == TYPE_POINTER)
:   lda paramKind
    cmp #TYPE_POINTER
    bne :+
    lda argKind
    cmp #TYPE_POINTER
    bne :+
    jsr checkPointerParam
    jmp NX

    ; if (paramType.kind == TYPE_ROUTINE_POINTER)
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

:   ldz #paramPtrOffset
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
    jmp L1

DN:
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

.proc checkRecordParam
    ; Compare paramType.paramFields with argType.paramFields
    ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr3
    ldq stackPointer
    jsr getBaseType
    stq ptr4
    ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr4),z
    stq ptr4
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

.proc checkIntegerParam
    lda argKind
    ldx paramKind
    jsr getTypeConversion
    cmp #TYPE_VOID
    bne :+
    lda #errInvalidType
    jsr typeCheckError
:   rts
.endproc

.proc checkStringVarParam
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
    beq L2
    stq ptr3
    ; if (argType.subtype != paramType.subtype)
    ldz #type::subtype
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr4
    ldx #0
:   lda ptr3,x
    cmp ptr4,x
    bne L1
    inx
    cpx #4
    bne :-
    bra L2
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

.proc checkPointerParam
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr3
    ldz #type::subtype
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr4
    ldz #type::kind
    nop
    lda (ptr3),z
    nop
    cmp (ptr4),z
    beq :+
    lda #errIncompatibleTypes
    jsr typeCheckError
:   rts
.endproc

.proc checkRoutinePointerParam
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
