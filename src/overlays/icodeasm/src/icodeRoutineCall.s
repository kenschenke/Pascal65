;
; icodeRoutineCall.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"
.include "icode.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

; Local Variables
paramTypeKindOffset = 0
paramTypeFlagsOffset = paramTypeKindOffset + 1
paramsOffset = paramTypeFlagsOffset + 1
paramNumOffset = paramsOffset + 4
levelOffset = paramNumOffset + 1
argPtrOffset = levelOffset + 1
; Parameters on stack from caller
paramPtrsOffset = argPtrOffset + 4
paramTypesOffset = paramPtrsOffset + 4
isRtnPtrOffset = paramTypesOffset + 4
isLibraryOffset = isRtnPtrOffset + 1
typePtrOffset = isLibraryOffset + 1
symPtrOffset = typePtrOffset + 4
exprPtrOffset = symPtrOffset + 4

.export icodeRoutineCall

.import loadStackValue, lblRoutineReturn, icodeFormatLabel, icodeVar
.import icodeWriteInstruction, icodeOper1Short, icodeOper1Label, icodeOper2Label
.import icodeExprRead, lblDeclInit, icodeOper2Short, icodeExpr

.bss

argKind: .res 1

.code

; Parameters on the stack, bottom to top
;   routine expression
;   symbol
;   type
;   isLibrary
;   isRtnptr
;   paramTypes
;   paramPtrs
.proc icodeRoutineCall
    ; Store local variables
    jsr pushQZero           ; current argument ptr
    lda #0
    jsr pushA               ; level
    lda #0
    jsr pushA               ; paramNum
    jsr pushQZero           ; params
    lda #0
    jsr pushA               ; param type flags
    lda #0
    jsr pushA               ; param type kind

    ldz #symPtrOffset
    jsr loadStackValue
    stq ptr1

    ; Populate the first argument pointer
    ldz #exprPtrOffset
    jsr loadStackValue
    jsr storeNextArgPtr

    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #paramsOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-

    ldz #symPtrOffset
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
    ldz #decl::node
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #symbol::level
    nop
    lda (ptr1),z
    ldz #levelOffset
    nop
    sta (stackPointer),z

    ; Set up the stack frame
:   ldz #exprPtrOffset
    jsr loadStackValue
    stq intOp32
    lda #<lblRoutineReturn
    ldx #>lblRoutineReturn
    jsr icodeFormatLabel
    ldz #isRtnPtrOffset
    nop
    lda (stackPointer),z
    beq NP
    ; Routine pointer
    ldz #symPtrOffset
    jsr loadStackValue
    stq ptr1
    lda #IC_VDR
    jsr pushA
    lda #TYPE_ROUTINE_POINTER
    jsr pushA
    ldz #symbol::level
    nop
    lda (ptr1),z
    jsr pushA
    ldz #symbol::offset
    nop
    lda (ptr1),z
    jsr pushA
    jsr icodeVar
    jsr icodeOper1Label
    lda #IC_PPF
    jsr icodeWriteInstruction
    bra L1

    ; Not a routine pointer
NP: ldz #levelOffset
    nop
    lda (stackPointer),z
    bne :+
    lda #2
    nop
    sta (stackPointer),z
:   jsr icodeOper1Short
    jsr icodeOper2Label
    lda #IC_PUF
    jsr icodeWriteInstruction

    ; Push the arguments onto the stack
L1: ldz #argPtrOffset
    jsr loadStackValue
    jsr isQZero
    bne :+
    jmp LE

:   ldz #paramTypeKindOffset
    lda #TYPE_VOID
    nop
    sta (stackPointer),z
    ldz #paramTypeFlagsOffset
    lda #0
    nop
    sta (stackPointer),z

    ldz #paramsOffset
    jsr loadStackValue
    jsr isQZero
    beq :+
    stq ptr1
    ldz #param_list::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    ldz #paramTypeKindOffset
    nop
    sta (stackPointer),z
    ldz #type::flags
    nop
    lda (ptr1),z
    ldz #paramTypeFlagsOffset
    nop
    sta (stackPointer),z

    ; Clear the current paramTypes
    ldz #paramTypesOffset
    jsr loadStackValue
    stq ptr1
    ldz #paramNumOffset
    nop
    lda (stackPointer),z
    taz
    lda #0
    nop
    sta (ptr1),z

    ; Look at the parameter type
    ldz #paramTypeKindOffset
    nop
    lda (stackPointer),z
    cmp #TYPE_DECLARED
    bne :+
    jsr declaredParam
    ldz #paramTypeKindOffset
    nop
    lda (stackPointer),z

    ; Is this parameter a record or array and is being passed by value?
:   cmp #TYPE_RECORD
    bne :+
    jsr isParamByValue
    bne ST                  ; Branch if being passed by reference
    jsr copyHeap
    jmp NX
:   cmp #TYPE_ARRAY
    bne ST
    jsr isParamByValue
    bne ST                  ; Branch if being passed by reference
    jsr copyHeap
    jmp NX

    ; Is this parameter a string variable and being passed by value?
ST: ldz #paramTypeKindOffset
    nop
    lda (stackPointer),z
    cmp #TYPE_STRING_VAR
    bne BR
    jsr isParamByValue
    bne BR
    jsr copyString
    jmp NX

    ; Is this parameter being passed by reference?
BR: jsr isParamByValue
    beq BV
    jsr passByReference
    jmp NX

BV: jsr passByValue

NX: ldz #argPtrOffset
    jsr loadStackValue
    jsr storeNextArgPtr
    ldz #paramsOffset
    jsr loadStackValue
    jsr isQZero
    bne :+
    ; Parameter is null.
    jsr incParamNum

    jmp L1
    ; Move to the next parameter
:   stq ptr1
    ldz #param_list::next
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #paramsOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    jsr incParamNum
    jmp L1

    ; End of arguments
LE: ldz #paramTypesOffset
    jsr loadStackValue
    stq ptr1
    ldz #paramNumOffset
    nop
    lda (stackPointer),z
    taz
    lda #END_OF_PARAMS
    nop
    sta (ptr1),z

    ldz #symPtrOffset
    jsr loadStackValue
    stq ptr1

    ldz #isRtnPtrOffset
    nop
    lda (stackPointer),z
    beq :+
    lda #IC_VDR
    jsr pushA
    lda #TYPE_ROUTINE_POINTER
    jsr pushA
    ldz #symbol::level
    nop
    lda (ptr1),z
    jsr pushA
    ldz #symbol::offset
    nop
    lda (ptr1),z
    jsr pushA
    jsr icodeVar
    bra DN

    ; Activate the new stack frame
:   ldz #levelOffset
    nop
    lda (stackPointer),z
    jsr icodeOper1Short
    lda #IC_ASF
    jsr icodeWriteInstruction

DN: jsr popA                ; param type kind
    jsr popA                ; param type flags
    jsr popQ                ; params
    jsr popA                ; paramNum
    jsr popA                ; level
    pha                     ; save level for returning to caller
    jsr popQ                ; argument ptr
    jsr popQ                ; paramPtrs
    jsr popQ                ; paramTypes
    jsr popA                ; isRtnPtr
    jsr popA                ; isLibrary
    jsr popQ                ; typePtr
    jsr popQ                ; symPtr
    jsr popQ                ; exprPtr
    pla                     ; pop level off stack for return to caller
    rts
.endproc

; This routine sets the Z flag if the parameter is passed by value
.proc isParamByValue
    ldz #paramTypeFlagsOffset
    nop
    lda (stackPointer),z
    and #TYPE_FLAG_ISBYREF
    rts
.endproc

; This routine converts the parameter into a string object and makes
; a copy of it to a second heap.
.proc copyString
    ldz #argPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeExprRead

    ldz #argPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::evalTypeKind
    nop
    lda (ptr1),z
    jsr icodeOper1Short
    lda #IC_SCV
    jsr icodeWriteInstruction

    ldz #paramTypesOffset
    jsr loadStackValue
    stq ptr1
    ldz #paramNumOffset
    nop
    lda (stackPointer),z
    taz
    lda #ARRAYDECL_STRING
    nop
    sta (ptr1),z

    rts
.endproc

; This routine allocates a second heap and makes a copy of the variable
.proc copyHeap
    ldz #argPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    jsr pushQ               ; keep a copy
    ldq ptr1
    jsr icodeExprRead

    jsr popQ
    stq ptr1
    ldz #expr::name
    neg
    neg
    nop
    lda (ptr1),z
    jsr scopeLookup
    stq ptr2
    ldz #symbol::decl
    neg
    neg
    nop
    lda (ptr2),z
    stq intOp32
    stq ptr2                    ; Save for later too
    lda #<lblDeclInit
    ldx #>lblDeclInit
    jsr icodeFormatLabel

    ldz #paramTypeKindOffset
    nop
    lda (stackPointer),z
    cmp #TYPE_RECORD
    beq LR
    lda #ARRAYDECL_ARRAY
    bra L1
LR: lda #ARRAYDECL_RECORD
L1: pha
    ldz #paramTypesOffset
    jsr loadStackValue
    stq ptr1
    ldz #paramNumOffset
    nop
    lda (stackPointer),z
    taz
    pla
    pha
    nop
    sta (ptr1),z

    ldz #paramPtrsOffset
    jsr loadStackValue
    stq ptr1
    ldz #paramNumOffset
    nop
    lda (stackPointer),z
    asl a
    asl a
    taz
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-

    jsr icodeOper1Label
    pla
    jsr icodeOper2Short
    lda #IC_DCC
    jsr icodeWriteInstruction
    rts
.endproc

.proc declaredParam
    ldz #paramsOffset
    jsr loadStackValue
    jsr isQZero
    bne :+
    rts
:   stq ptr1
    ldz #param_list::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #type::name
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr4
    jsr scopeLookup
    jsr isQZero
    bne :+
    rts
:   stq ptr1
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    ldz #paramTypeKindOffset
    nop
    sta (stackPointer),z
    rts
.endproc

.proc passByValue
    ldz #argPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeExprRead

    ldz #isLibraryOffset
    nop
    lda (stackPointer),z
    beq DN

    ldz #paramTypeKindOffset
    nop
    lda (stackPointer),z
    jsr isTypeInteger
    beq DN

    ; Compare the arg type to the param type
    ldz #argPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::evalTypeKind
    nop
    lda (ptr1),z
    sta argKind
    ldz #paramTypeKindOffset
    nop
    lda (stackPointer),z
    cmp argKind
    beq DN

    ; The argument being passed is an integer and a
    ; different type than the expected parameter.
    ; See if it needs to be sign-extended.
    pha                 ; Save the param type kind
    lda argKind
    jsr getTypeSize
    sta intOp2
    stx intOp2+1

    pla                 ; param type kind
    jsr getTypeSize
    sta intOp1
    stx intOp1+1

    jsr gtInt16
    beq DN              ; branch if param <= arg size

    ; If the parameter type expected is larger than the
    ; argument being passed, sign-extend it.

    lda argKind
    jsr icodeOper1Short
    ldz #paramTypeKindOffset
    nop
    lda (stackPointer),z
    sta icodeOper2Short
    lda #IC_CVI
    jsr icodeWriteInstruction

DN: rts
.endproc

.proc passByReference
    ldz #argPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    lda #0
    jsr pushA
    jsr icodeExpr
    rts
.endproc

; This routine stores the next argument pointer to the stack.
; The pointer to the argument expression is passed in Q.
; If this is the first argument, that pointer will be the
; expression for the routine itself. Otherwise, it's a pointer
; to the current argument.
.proc storeNextArgPtr
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #argPtrOffset
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

; This routine increments the paramNum
.proc incParamNum
    ldz #paramNumOffset
    nop
    lda (stackPointer),z
    clc
    adc #1
    nop
    sta (stackPointer),z
    rts
.endproc

.proc isTypeInteger
    cmp #TYPE_SHORTINT
    beq L1
    cmp #TYPE_BYTE
    beq L1
    cmp #TYPE_INTEGER
    beq L1
    cmp #TYPE_WORD
    beq L1
    cmp #TYPE_LONGINT
    beq L1
    cmp #TYPE_CARDINAL
L1: rts
.endproc

; Type kind passed in A.
; Size returned in A/X.
.proc getTypeSize
    ldx #0
    cmp #TYPE_REAL
    bne :+
    lda #4
    rts
:   cmp #TYPE_SHORTINT
    bne :+
    lda #1
    rts
:   cmp #TYPE_BYTE
    bne :+
    lda #1
    rts
:   cmp #TYPE_INTEGER
    bne :+
    lda #2
    rts
:   cmp #TYPE_WORD
    bne :+
    lda #2
    rts
:   cmp #TYPE_LONGINT
    bne :+
    lda #4
    rts
:   cmp #TYPE_CARDINAL
    bne :+
    lda #4
    rts
:   lda #0
    rts
.endproc
