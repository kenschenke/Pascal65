;
; icodeStdRoutineCall.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"
.include "icode.inc"
.include "asmlib.inc"
.include "symtab.inc"
.include "zeropage.inc"
.include "4510macros.inc"

argPtrOffset = 0
routineCodeOffset = argPtrOffset + 4

.export icodeStdRoutineCall, formatArrayDeclLabel

.import loadStackValue, icodeReadReadlnCall, icodeWriteWritelnCall
.import icodeExprRead, icodeOper1Short, icodeWriteInstruction, icodeDecIncCall
.import icodeExpr, icodeOper2Short, icodeOper3Short, icodeOper1Int
.import icodeOper1Label, icodeFormatLabel, lblDeclInit, lblParamDeclInit

.bss

lenCount: .res 2

.code

; Arguments passed on stack, bottom to top:
;   routine code
;   expression arguments
.proc icodeStdRoutineCall
    ldz #routineCodeOffset
    nop
    lda (stackPointer),z
    cmp #rcRead
    bne :+
    jsr readReadln
    jmp DN
:   cmp #rcReadln
    bne :+
    jsr readReadln
    jmp DN
:   cmp #rcReadStr
    bne :+
    jsr readReadln
    jmp DN
:   cmp #rcWrite
    bne :+
    jsr writeWriteln
    jmp DN
:   cmp #rcWriteln
    bne :+
    jsr writeWriteln
    jmp DN
:   cmp #rcWriteStr
    bne :+
    jsr writeWriteln
    jmp DN
:   cmp #rcAbs
    bne :+
    jsr absCall
    jmp DN
:   cmp #rcSqr
    bne :+
    jsr sqrCall
    jmp DN
:   cmp #rcRound
    bne :+
    jsr roundTrunc
    jmp DN
:   cmp #rcTrunc
    bne :+
    jsr roundTrunc
    jmp DN
:   cmp #rcPred
    bne :+
    jsr predSucc
    jmp DN
:   cmp #rcSucc
    bne :+
    jsr predSucc
    jmp DN
:   cmp #rcOrd
    bne :+
    jsr ordCall
    jmp DN
:   cmp #rcDec
    bne :+
    jsr decInc
    jmp DN
:   cmp #rcInc
    bne :+
    jsr decInc
    jmp DN
:   cmp #rcSetLength
    bne :+
    jsr setLengthCall
    jmp DN
:   cmp #rcLow
    bne :+
    jsr lowHighCall
    jmp DN
:   cmp #rcHigh
    bne :+
    jsr lowHighCall
    jmp DN
:   cmp #rcLength
    bne :+
    jsr lengthCall
    jmp DN
:   lda #TYPE_VOID

DN: pha
    jsr popQ
    jsr popA
    pla
    rts
.endproc

.proc readReadln
    ldz #argPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #routineCodeOffset
    nop
    lda (stackPointer),z
    jsr pushA
    ldq ptr1
    jsr pushQ
    jsr icodeReadReadlnCall
    lda #TYPE_VOID
    rts
.endproc

.proc writeWriteln
    ldz #argPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #routineCodeOffset
    nop
    lda (stackPointer),z
    jsr pushA
    ldq ptr1
    jsr pushQ
    jsr icodeWriteWritelnCall
    
    ldz #routineCodeOffset
    nop
    lda (stackPointer),z
    cmp #rcWriteStr
    bne :+
    lda #TYPE_STRING_OBJ
    rts
:   lda #TYPE_VOID
    rts
.endproc

.proc absCall
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
    pha
    jsr icodeOper1Short
    lda #IC_ABS
    jsr icodeWriteInstruction
    pla
    rts
.endproc

.proc sqrCall
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
    pha
    jsr icodeOper1Short
    lda #IC_SQR
    jsr icodeWriteInstruction
    pla
    cmp #TYPE_REAL
    beq :+
    lda #TYPE_LONGINT
:   rts
.endproc

.proc roundTrunc
    ldz #argPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeExprRead
    ldz #routineCodeOffset
    nop
    lda (stackPointer),z
    cmp #rcRound
    bne :+
    lda #IC_ROU
    bra L1
:   lda #IC_TRU
L1: jsr icodeWriteInstruction
    lda #TYPE_INTEGER
    rts
.endproc

.proc predSucc
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
    cmp #TYPE_ENUMERATION
    beq L1
    cmp #TYPE_ENUMERATION_VALUE
    bne L2
L1: lda #TYPE_WORD
L2: pha
    jsr icodeOper1Short
    ldz #routineCodeOffset
    nop
    lda (stackPointer),z
    cmp #rcPred
    beq L3
    lda #IC_SUC
    bra L4
L3: lda #IC_PRE
L4: jsr icodeWriteInstruction
    pla
    rts
.endproc

.proc ordCall
    ldz #argPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeExprRead
    lda #TYPE_INTEGER
    rts
.endproc

.proc decInc
    ldz #argPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #routineCodeOffset
    nop
    lda (stackPointer),z
    jsr pushA
    ldq ptr1
    jsr pushQ
    jsr icodeDecIncCall
    rts
.endproc

; SetLength(arr, n)
; The array is pushed as a variable reference (the address of its slot,
; because resizing moves the array), then the new length as a LongInt so
; the runtime can range check any integer type. SAL's operand is the label
; of the array's declaration block.
.proc setLengthCall
    ; The array as a variable reference
    jsr getFirstArg
    jsr pushQ
    lda #0
    jsr pushA
    jsr icodeExpr

    ; The new length
    jsr getSecondArg
    jsr icodeExprRead
    jsr getSecondArg
    stq ptr1
    ldz #expr::evalTypeKind
    nop
    lda (ptr1),z
    cmp #TYPE_LONGINT
    beq L1
    cmp #TYPE_CARDINAL
    beq L1
    jsr icodeOper1Short
    lda #TYPE_LONGINT
    jsr icodeOper2Short
    lda #IC_CVI
    jsr icodeWriteInstruction

    ; The type checker only lets a name through
L1: jsr getFirstArg
    stq ptr1
    ldz #expr::node
    neg
    neg
    nop
    lda (ptr1),z
    jsr formatArrayDeclLabel
    jsr icodeOper1Label
    lda #IC_SAL
    jsr icodeWriteInstruction
    lda #TYPE_VOID
    rts
.endproc

; Low(arr) and High(arr)
; Both are read from the array's header: the low index is the first
; word and the high index is the second.
.proc lowHighCall
    jsr pushArrayAddress
    ldz #routineCodeOffset
    nop
    lda (stackPointer),z
    cmp #rcHigh
    bne :+
    jsr addHighOffset
:   jsr readHeaderWord
    lda #TYPE_INTEGER
    rts
.endproc

; Length(arr)
; A static array's length is known at compile time. Reading Low and High
; would evaluate the argument twice. A dynamic array's low index is
; always 0, so its length is High + 1.
.proc lengthCall
    jsr getFirstArg
    stq ptr1
    ldz #expr::evalType
    neg
    neg
    nop
    lda (ptr1),z
    jsr getBaseType
    stq ptr2
    ldz #type::flags
    nop
    lda (ptr2),z
    and #TYPE_FLAG_ISDYNAMIC
    bne DY

    jsr staticLength
    jsr icodeOper1Int
    lda #IC_PSH
    jsr icodeWriteInstruction
    lda #TYPE_INTEGER
    rts

DY: jsr pushArrayAddress
    jsr addHighOffset
    jsr readHeaderWord
    lda #1
    jsr icodeOper1Short
    lda #IC_PSH
    jsr icodeWriteInstruction
    lda #TYPE_INTEGER
    jsr icodeOper1Short
    lda #TYPE_BYTE
    jsr icodeOper2Short
    lda #TYPE_INTEGER
    jsr icodeOper3Short
    lda #IC_ADD
    jsr icodeWriteInstruction
    lda #TYPE_INTEGER
    rts
.endproc

; This routine calculates the number of elements in a static array:
; (size - 6) / element size. The array type is in ptr2.
; The count is returned in A/X.
.proc staticLength
    lda #0
    sta lenCount
    sta lenCount+1

    ldz #type::size
    nop
    lda (ptr2),z
    sec
    sbc #6
    sta intOp1
    inz
    nop
    lda (ptr2),z
    sbc #0
    sta intOp1+1

    ; The resolver stores the element size in the subtype
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    ldz #type::size
    nop
    lda (ptr2),z
    sta intOp2
    inz
    nop
    lda (ptr2),z
    sta intOp2+1
    ora intOp2
    beq DN

L1: jsr ltUint16
    bne DN
    jsr subInt16
    inc lenCount
    bne L1
    inc lenCount+1
    bra L1

DN: lda lenCount
    ldx lenCount+1
    rts
.endproc

; This routine pushes the address of the header of the array in the first
; argument. An array embedded in a record or another array is at its
; address. Otherwise the variable holds the address of the array's heap.
.proc pushArrayAddress
    jsr getFirstArg
    stq ptr1
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_FIELD
    beq :+
    cmp #EXPR_SUBSCRIPT
    beq :+
    ldq ptr1
    jmp icodeExprRead
:   ldq ptr1
    jsr pushQ
    lda #0
    jsr pushA
    jmp icodeExpr
.endproc

; This routine adds 2 to the address on top of the runtime stack, the
; offset of the high index in an array header.
.proc addHighOffset
    lda #2
    jsr icodeOper1Short
    lda #IC_PSH
    jsr icodeWriteInstruction
    lda #TYPE_WORD
    jsr icodeOper1Short
    lda #TYPE_WORD
    jsr icodeOper2Short
    lda #TYPE_WORD
    jsr icodeOper3Short
    lda #IC_ADD
    jmp icodeWriteInstruction
.endproc

; This routine replaces the address on top of the runtime stack with
; the Integer at that address.
.proc readHeaderWord
    lda #TYPE_INTEGER
    jsr icodeOper1Short
    lda #IC_MEM
    jmp icodeWriteInstruction
.endproc

; This routine returns the expression of the first argument in Q.
.proc getFirstArg
    ldz #argPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    rts
.endproc

; This routine returns the expression of the second argument in Q.
.proc getSecondArg
    ldz #argPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    rts
.endproc

; This routine formats the label of an array's declaration block in
; icodeLabel. The array's symbol is passed in Q. A variable's block is
; named for its decl. A parameter has no decl, so its block is named for
; its symbol (see icodeRoutineDeclaration).
.proc formatArrayDeclLabel
    stq ptr1
    stq intOp32
    ldz #symbol::decl
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq PR
    stq intOp32
    lda #<lblDeclInit
    ldx #>lblDeclInit
    jmp icodeFormatLabel
PR: lda #<lblParamDeclInit
    ldx #>lblParamDeclInit
    jmp icodeFormatLabel
.endproc
