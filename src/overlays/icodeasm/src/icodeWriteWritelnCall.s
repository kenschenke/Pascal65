;
; icodeWriteWritelnCall.s
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

writingBytesOffset = 0
argPtrOffset = writingBytesOffset + 1
routineCodeOffset = argPtrOffset + 4

.export icodeWriteWritelnCall

.import loadStackValue, icodeOper1Short, icodeOper2Short, icodeWriteInstruction
.import icodeOper1Int, icodeExprRead

.bss

valType: .res 1

.code

; Arguments passed on stack, from bottom to top
;   routine code
;   argument list
.proc icodeWriteWritelnCall
    lda #0
    jsr pushA                   ; writingBytes

    ldz #routineCodeOffset
    nop
    lda (stackPointer),z
    cmp #rcWriteStr
    beq WS
    ldz #argPtrOffset
    jsr loadStackValue
    jsr isQZero
    bne :+
    lda #FH_STDIO
    bra SH

:   stq ptr1
    ldz #expr::evalType
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    ldz #type::kind
    nop
    lda (ptr2),z
    cmp #TYPE_FILE
    beq FO
    cmp #TYPE_TEXT
    bne SI
FO: cmp #TYPE_FILE
    bne :+
    lda #1
    ldz #writingBytesOffset
    nop
    sta (stackPointer),z
:   ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeExprRead
    jsr nextArg
    lda #FH_FILENUM
    bra SH
SI: lda #FH_STDIO
    bra SH

WS: lda #FH_STRING
SH: jsr icodeOper1Short
    lda #0
    jsr icodeOper2Short
    lda #IC_SFH
    jsr icodeWriteInstruction

    ; Loop through the arguments to write
L1: ldz #argPtrOffset
    jsr loadStackValue
    stq ptr1
    jsr isQZero
    bne :+
    jmp EL

:   ldz #writingBytesOffset
    nop
    lda (stackPointer),z
    beq :+
    jmp WB

:   ldz #expr::evalType
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    ldz #type::kind
    nop
    lda (ptr2),z
    cmp #TYPE_RECORD
    bne :+
    jsr nextArg
    bra L1

:   ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeExprRead
    sta valType

    ldz #argPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::width
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    jsr icodeExprRead
    bra L2
:   lda #0
    jsr icodeOper1Short
    lda #IC_PSH
    jsr icodeWriteInstruction

L2: ldz #argPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::precision
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    jsr icodeExprRead
    bra L3
:   lda #$ff
    jsr icodeOper1Short
    lda #IC_PSH
    jsr icodeWriteInstruction

L3: ldz #argPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::evalType
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    ldz #type::kind
    nop
    lda (ptr2),z
    cmp #TYPE_ARRAY
    bne :+
    lda valType
:   jsr icodeOper1Short
    lda #IC_OUT
    jsr icodeWriteInstruction
    jsr nextArg
    jmp L1

WB: ldz #argPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (stackPointer),z
    jsr icodeExprRead
    ldz #argPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::evalType
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    sta valType
    ldz #type::size+1
    nop
    lda (ptr1),z
    tax
    dez
    nop
    lda (ptr1),z
    jsr icodeOper1Int
    lda #IC_PSH
    jsr icodeWriteInstruction

    lda valType
    cmp #TYPE_ARRAY
    beq AR
    cmp #TYPE_RECORD
    bne L4
AR: lda #TYPE_HEAP_BYTES
    bra L5
L4: lda #TYPE_SCALAR_BYTES
L5: jsr icodeOper1Short
    lda #IC_OUT
    jsr icodeWriteInstruction
    jsr nextArg
    jmp L1

EL: ldz #routineCodeOffset
    nop
    lda (stackPointer),z
    cmp #rcWriteln
    bne :+
    lda #IC_ONL
    jsr icodeWriteInstruction
:   ldz #routineCodeOffset
    nop
    lda (stackPointer),z
    cmp #rcWriteStr
    bne :+
    lda #IC_FSO
    jsr icodeWriteInstruction
:   lda #0
    jsr icodeOper1Short
    lda #0
    jsr icodeOper2Short
    lda #IC_SFH
    jsr icodeWriteInstruction

    jsr popA
    jsr popQ
    jsr popA
    rts
.endproc

.proc nextArg
    ldz #argPtrOffset
    jsr loadStackValue
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
