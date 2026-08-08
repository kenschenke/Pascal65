;
; checkWriteWritelnCall.s
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

typeOffset = 0
firstOffset = typeOffset + .sizeof(type)
exprLeftOffset = firstOffset + 1
exprTypeOffset = exprLeftOffset + 4
fileTypeSubOffset = exprTypeOffset + 4
routineCodeOffset = fileTypeSubOffset + .sizeof(type)
argOffset = routineCodeOffset + 1

.export checkWriteWritelnCall

.import typeCheckError, loadStackValue, exprTypeCheck, checkIntegerBaseType
.import checkArraysSameType, isAssignmentCompatible, isTypeInteger

.proc checkWriteWritelnCall
    lda #.sizeof(type)          ; fileTypeSub
    jsr pushBlock
    jsr pushQZero               ; exprType
    jsr pushQZero               ; exprLeft

    lda #1
    jsr pushA                   ; first

    ; Push an empty type onto the stack
    lda #.sizeof(type)
    jsr pushBlock

    lda #0
    ldz #fileTypeSubOffset
    nop
    sta (stackPointer),z

    ; Loop through the arguments
L1: ldz #argOffset
    jsr loadStackValue
    jsr isQZero
    bne :+
    jmp DN

:   stq ptr1
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #exprLeftOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-

    ; Evaluate the argument expression type
    ldq stackPointer
    stq ptr1
    ldz #exprLeftOffset
    jsr loadStackValue
    jsr pushQ                   ; expression
    jsr pushQZero               ; record symbol table
    ldq ptr1
    jsr pushQ                   ; type
    lda #0
    jsr pushA                   ; parentIsFuncCall
    jsr exprTypeCheck
    ldq stackPointer
    jsr getBaseType
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
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ARRAY
    bne :+
    jsr checkArray
    jmp NX
:   cmp #TYPE_RECORD
    bne :+
    jsr checkRecord
    jmp NX
:   cmp #TYPE_REAL
    bne :+
    jsr checkWidthAndPrecision
    jmp NX
:   cmp #TYPE_CHARACTER
    bne :+
    jsr checkWidthAndPrecision
    jmp NX
:   cmp #TYPE_BOOLEAN
    bne :+
    jsr checkWidthAndPrecision
    jmp NX
:   cmp #TYPE_FILE
    bne :+
    jsr checkFile
    jmp NX
:   cmp #TYPE_TEXT
    bne :+
    jsr checkText
    jmp NX
:   cmp #TYPE_STRING_LITERAL
    bne :+
    ; do nothing
    jmp NX
:   cmp #TYPE_STRING_VAR
    bne :+
    ; do nothing
    jmp NX
:   cmp #TYPE_STRING_OBJ
    bne :+
    ; do nothing
    jmp NX
:   jsr isTypeInteger
    bne :+
    jsr checkWidthAndPrecision
    jmp NX
:   lda #errIncompatibleTypes
    jsr typeCheckError

NX: ldz #firstOffset
    nop
    lda (stackPointer),z
    bne L2
    ldz #fileTypeSubOffset
    nop
    lda (stackPointer),z
    beq L2
    cmp #TYPE_ARRAY
    beq L2
    cmp #TYPE_RECORD
    beq L2

    pha
    ldz #exprTypeOffset
    jsr loadStackValue
    stq ptr1
    pla
    jsr pushA
    ldq ptr1
    jsr pushQ
    jsr isAssignmentCompatible
    beq L2
    lda #errIncompatibleTypes
    jsr typeCheckError

L2: lda #0
    ldz #firstOffset
    nop
    sta (stackPointer),z
    ldz #argOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #argOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    lda #0
    ldz #firstOffset
    nop
    sta (stackPointer),z
    jmp L1

DN: lda #.sizeof(type)
    jsr popBlock            ; type
    jsr popA                ; first
    jsr popQ                ; exprLeft
    jsr popQ                ; exprType
    lda #.sizeof(type)
    jsr popBlock            ; fileTypeSub
    jsr popA                ; routineCode
    jsr popQ                ; arg
    rts
.endproc

.proc checkArray
    ldz #exprTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jsr getBaseType
    stq ptr1
    ldz #fileTypeSubOffset
    nop
    lda (stackPointer),z
    beq L1
    lda #fileTypeSubOffset
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq stackPointer
    clc
    adcq intOp32
    stq ptr2
    ldz #exprTypeOffset
    jsr loadStackValue
    jsr pushQ
    ldq ptr2
    jsr pushQ
    jsr checkArraysSameType
    rts
L1: ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_CHARACTER
    beq :+
    lda #errIncompatibleTypes
    jsr typeCheckError
:   jsr checkWidthAndPrecision
    rts
.endproc

.proc checkRecord
    ldz #exprTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #type::symtab
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    lda #fileTypeSubOffset
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq stackPointer
    clc
    adcq intOp32
    stq ptr3
    ldz #type::symtab
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr3
    ldx #0
:   lda ptr2,x
    cmp ptr3,x
    bne :+
    inx
    cpx #4
    bne :-
    rts
:   lda #errIncompatibleTypes
    jsr typeCheckError
    rts
.endproc

.proc checkWidthAndPrecision
    ldz #exprLeftOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::width
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    jsr checkIntegerBaseType
    ldz #exprLeftOffset
    jsr loadStackValue
    stq ptr1
    ldz #expr::precision
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    jsr checkIntegerBaseType
    rts
.endproc

.proc checkFile
    ldz #firstOffset
    nop
    lda (stackPointer),z
    bne :+
    lda #errIncompatibleTypes
    jsr typeCheckError
:   ldz #routineCodeOffset
    nop
    lda (stackPointer),z
    cmp #rcWrite
    beq :+
    lda #errIncompatibleTypes
    jsr typeCheckError
:   ldz #exprTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    jsr getBaseType
    jsr copyFileSubtype
:   rts
.endproc

.proc checkText
    ldz #firstOffset
    nop
    lda (stackPointer),z
    bne :+
    lda #errIncompatibleTypes
    jsr typeCheckError
:   ldz #routineCodeOffset
    nop
    lda (stackPointer),z
    cmp #rcWriteStr
    bne :+
    lda #errIncompatibleTypes
    jsr typeCheckError
:   rts
.endproc

.proc copyFileSubtype
    stq ptr1                ; subtype to copy from in ptr1

    ; Set ptr2 to point to the filesubtype on the stack
    lda #fileTypeSubOffset
    ldx #0
    ldy #0
    ldz #0
    stq intOp32
    ldq stackPointer
    clc
    adcq intOp32
    stq ptr2

    ; Copy the type from ptr1 to ptr2
    ldz #0
:   nop
    lda (ptr1),z
    nop
    sta (ptr2),z
    inz
    cpz #.sizeof(type)
    bne :-

    rts
.endproc
