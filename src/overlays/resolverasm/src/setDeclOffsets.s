;
; setDeclOffsets.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; setDeclOffsets routine

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

levelOffset = 0
startingOffset = 1
currentDecl = 3

.export setDeclOffsets

.import findUnit

; This routine calculates declaration offsets.
; On input on the runtime stack, bottom to top:
;    First declaration in chain
;    Starting offset (2 bytes)
;    Level (1 byte)
.proc setDeclOffsets
L1: ldz #currentDecl
    neg
    neg
    nop
    lda (stackPointer),z
    jsr isQZero
    bne :+
    jmp L9

:   stq ptr1
    ldz #decl::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    ldz #type::kind
    nop
    lda (ptr2),z
    cmp #TYPE_PROGRAM
    bne :+
    jsr setProgramOffsets
    jmp L8
:   cmp #TYPE_UNIT
    bne :+
    jsr setUnitOffsets
    jmp L8
:   cmp #TYPE_FUNCTION
    bne :+
    jsr setRoutineOffsets
    jmp L8
:   cmp #TYPE_PROCEDURE
    bne :+
    jsr setRoutineOffsets
    jmp L8
:   jsr setVarOffset

L8: ldz #currentDecl
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #decl::next
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #currentDecl
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    jmp L1

L9: jsr popA
    jsr popAX
    pha
    phx
    jsr popQ
    plx
    pla
    rts
.endproc

.proc setProgramOffsets
    ldz #decl::code
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #levelOffset
    nop
    lda (stackPointer),z
    clc
    adc #1
    pha
    
    ldz #stmt::decl
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    lda #0
    tax
    jsr pushAX
    pla
    jsr pushA
    jsr setDeclOffsets
    sta tmp1
    stx tmp2
    ldz #startingOffset
    nop
    lda (stackPointer),z
    clc
    adc tmp1
    nop
    sta (stackPointer),z
    inz
    nop
    lda (stackPointer),z
    adc tmp2
    nop
    sta (stackPointer),z
    rts
.endproc

.proc setUnitOffsets
    ldz #decl::name
    neg
    neg
    nop
    lda (ptr1),z
    jsr findUnit
    jsr isQZero
    bne :+
    rts
:   stq ptr2
    ldz #unit::astRoot
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2                ; unit decl in ptr2
    ldz #decl::code
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr3                ; stmt block in ptr3
    ldz #stmt::decl
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr4                ; first block declaration in ptr4
    ; Get current offset and store in tmp1/tmp2
    ldz #startingOffset
    nop
    lda (stackPointer),z
    sta tmp1
    inz
    nop
    lda (stackPointer),z
    sta tmp2
    ; Level in tmp3
    ldz #levelOffset
    nop
    lda (stackPointer),z
    sta tmp3
    inc tmp3
    ; Call setDeclOffset for stmt block
    ldq ptr3
    jsr pushQ               ; save stmt block for next call
    ldq ptr4
    jsr pushQ
    lda tmp1
    ldx tmp2
    jsr pushAX
    lda tmp3
    jsr pushA
    jsr setDeclOffsets
    pha
    phx
    jsr popQ
    stq ptr3
    ldz #levelOffset
    nop
    lda (stackPointer),z
    sta tmp3
    inc tmp3
    ldz #stmt::interfaceDecl
    neg
    neg
    nop
    lda (ptr3),z
    jsr pushQ
    plx
    pla
    jsr pushAX
    lda tmp3
    jsr pushA
    jsr setDeclOffsets
    rts
.endproc

.proc setRoutineOffsets
    ldz #type::flags
    nop
    lda (ptr2),z
    and #TYPE_FLAG_ISFORWARD
    beq :+
    rts

:   ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr3

    lda #0
    sta intOp1          ; childOffset
    sta intOp1+1

L1: ldq ptr3
    jsr isQZero
    beq L2
    inw intOp1
    ldz #param_list::next
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr3
    bra L1

L2: ldz #decl::node
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L3
    stq ptr4
    ldz #levelOffset
    nop
    lda (stackPointer),z
    clc
    adc #1
    ldz #symbol::level
    nop
    sta (ptr4),z

L3: ldz #levelOffset
    nop
    lda (stackPointer),z
    clc
    adc #1
    pha
    ldz #decl::code
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    ldz #stmt::decl
    neg
    neg
    nop
    lda (ptr2),z
    jsr pushQ
    lda intOp1
    ldx intOp1+1
    jsr pushAX
    pla
    jsr pushA
    jsr setDeclOffsets
    rts
.endproc

.proc setVarOffset
    ldz #type::kind
    nop
    lda (ptr2),z
    cmp #TYPE_BOOLEAN
    beq L1
    cmp #TYPE_CHARACTER
    beq L1
    cmp #TYPE_BYTE
    beq L1
    cmp #TYPE_SHORTINT
    beq L1
    cmp #TYPE_INTEGER
    beq L1
    cmp #TYPE_WORD
    beq L1
    cmp #TYPE_LONGINT
    beq L1
    cmp #TYPE_CARDINAL
    beq L1
    cmp #TYPE_ENUMERATION
    beq L1
    cmp #TYPE_REAL
    beq L1
    cmp #TYPE_STRING_LITERAL
    beq L1
    cmp #TYPE_STRING_VAR
    beq L1
    cmp #TYPE_ARRAY
    beq L1
    cmp #TYPE_DECLARED
    beq L1
    cmp #TYPE_RECORD
    beq L1
    cmp #TYPE_SUBRANGE
    beq L1
    cmp #TYPE_FILE
    beq L1
    cmp #TYPE_TEXT
    beq L1
    cmp #TYPE_POINTER
    beq L1
    cmp #TYPE_ROUTINE_POINTER
    beq L1
    rts

L1: ldz #decl::node
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr3
    ldz #decl::kind
    nop
    lda (ptr1),z
    cmp #DECL_CONST
    beq L2
    cmp #DECL_VARIABLE
    beq L2
    bra L3

L2: ldz #startingOffset
    nop
    lda (stackPointer),z
    sta intOp1
    clc
    adc #1
    nop
    sta (stackPointer),z
    inz
    nop
    lda (stackPointer),z
    sta intOp1+1
    adc #0
    nop
    sta (stackPointer),z
    ldz #symbol::offset
    lda intOp1
    nop
    sta (ptr3),z
    inz
    lda intOp1+1
    nop
    sta (ptr3),z

L3: ldz #levelOffset
    nop
    lda (stackPointer),z
    ldz #symbol::level
    nop
    sta (ptr3),z
    rts
.endproc
