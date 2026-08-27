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

.export icodeStdRoutineCall

.import loadStackValue, icodeReadReadlnCall, icodeWriteWritelnCall
.import icodeExprRead, icodeOper1Short, icodeWriteInstruction, icodeDecIncCall

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
