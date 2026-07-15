;
; icodeReadReadlnCall.s
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

readingBytesOffset = 0
argPtrOffset = readingBytesOffset + 1
routineCodeOffset = argPtrOffset + 4

.export icodeReadReadlnCall

.import loadStackValue, icodeOper1Short, icodeOper2Short, icodeWriteInstruction
.import icodeExpr, icodeOper1Int

.bss

exprPtr: .res 4

.code

; Arguments passed on stack, from bottom to top
;   routine code
;   argument list
.proc icodeReadReadlnCall
    lda #0
    jsr pushA               ; readingBytes

    ; Look at the first argument to see if reading from a file
    ; or the keyboard.
    ldz #argPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::evalTypeKind
    nop
    lda (ptr1),z
    cmp #TYPE_FILE
    beq FI
    cmp #TYPE_TEXT
    bne KI

FI: cmp #TYPE_FILE
    bne :+
    lda #1
    ldz #readingBytesOffset
    nop
    sta (stackPointer),z
:   jsr nextArg
    lda #FH_FILENUM
    bra SF

KI: lda #FH_STDIO
SF: jsr icodeOper1Short
    lda #1
    jsr icodeOper2Short
    lda #IC_SFH
    jsr icodeWriteInstruction

    ; Loop through the parameters to Read
L1: ldz #argPtrOffset
    jsr loadStackValue
    jsr isQZero
    bne :+
    jmp EL

:   stq ptr1
    stq exprPtr

    ldz #readingBytesOffset
    nop
    lda (stackPointer),z
    bne RB

    ldz #expr::evalTypeKind
    nop
    lda (ptr1),z
    pha
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    lda #0
    jsr pushA
    jsr icodeExpr
    pla
    jsr icodeOper1Short
    lda #IC_INP
    jsr icodeWriteInstruction
    jsr nextArg
    bra L1

RB: ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    ldz #expr::evalTypeKind
    nop
    lda (ptr1),z
    cmp #TYPE_ARRAY
    beq AR
    cmp #TYPE_RECORD
    bne NN
AR: lda #1
    bra IE
NN: lda #0
IE: jsr pushA
    jsr icodeExpr

    ldq exprPtr
    stq ptr1
    ldz #expr::evalTypeSize+1
    nop
    lda (ptr1),z
    tax
    dez
    nop
    lda (ptr1),z
    jsr icodeOper1Int
    lda #IC_PSH
    jsr icodeWriteInstruction

    ldq exprPtr
    stq ptr1
    ldz #expr::evalTypeKind
    nop
    lda (ptr1),z
    cmp #TYPE_ARRAY
    beq L2
    cmp #TYPE_RECORD
    bne L3
L2: lda #TYPE_HEAP_BYTES
    bra L4
L3: lda #TYPE_SCALAR_BYTES
L4: jsr icodeOper1Short
    lda #IC_INP
    jsr icodeWriteInstruction
    jsr nextArg
    jmp L1

EL: ldz #routineCodeOffset
    nop
    lda (stackPointer),z
    cmp #rcReadln
    bne :+
    lda #IC_CNL
    jsr icodeWriteInstruction

:   lda #0
    jsr icodeOper1Short
    lda #1
    jsr icodeOper2Short
    lda #IC_SFH
    jsr icodeWriteInstruction

    jsr popA
    jsr popQ
    jsr popA
    rts
.endproc

; This routine updates the argPtr to the next argument in the parameters.
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
