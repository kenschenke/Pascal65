;
; getTypeSize.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; getTypeSize routine

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

sizeOffset = 0
typeOffset = 2

.export getTypeSize

.import getArraySize, getRecordSize, getDeclaredSize

; Type pointer passed in Q
; This routine is recursive so everything is stored on the stack.
.proc getTypeSize
    stq ptr1
    jsr pushQ           ; Store type pointer on stack
    lda #0
    tax
    jsr pushAX          ; Store size on stack

    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_BOOLEAN
    bne :+
    lda #1
    jmp L8
:   cmp #TYPE_SHORTINT
    bne :+
    lda #1
    jmp L8
:   cmp #TYPE_BYTE
    bne :+
    lda #1
    jmp L8
:   cmp #TYPE_CHARACTER
    bne :+
    lda #1
    jmp L8
:   cmp #TYPE_INTEGER
    bne :+
    lda #2
    jmp L8
:   cmp #TYPE_WORD
    bne :+
    lda #2
    jmp L8
:   cmp #TYPE_REAL
    bne :+
    lda #4
    jmp L8
:   cmp #TYPE_LONGINT
    bne :+
    lda #4
    jmp L8
:   cmp #TYPE_CARDINAL
    bne :+
    lda #4
    jmp L8
:   cmp #TYPE_ENUMERATION
    bne :+
    lda #2
    jmp L8
:   cmp #TYPE_ENUMERATION_VALUE
    bne :+
    lda #2
    jmp L8
:   cmp #TYPE_STRING_LITERAL
    bne :+
    lda #2
    jmp L8
:   cmp #TYPE_FILE
    bne :+
    lda #4
    jmp L8
:   cmp #TYPE_TEXT
    bne :+
    lda #4
    jmp L8
:   cmp #TYPE_STRING_OBJ
    bne :+
    lda #2
    jmp L8
:   cmp #TYPE_STRING_VAR
    bne :+
    lda #2
    jmp L8
:   cmp #TYPE_ARRAY
    bne :+
    jsr getArraySize
    jsr storeSize
    jmp L9
:   cmp #TYPE_SUBRANGE
    bne :+
    jsr getSubtypeSize
    jmp L8
:   cmp #TYPE_RECORD
    bne :+
    jsr getRecordSize
    jmp L9
:   cmp #TYPE_DECLARED
    bne :+
    jsr getDeclaredSize
    jmp L8
:   cmp #TYPE_FUNCTION
    bne :+
    jsr getSubtypeSize
    jmp L8
:   cmp #TYPE_POINTER
    bne :+
    jsr getSubtypeSize
    jmp L8
:   cmp #TYPE_ROUTINE_ADDRESS
    bne :+
    lda #4
    jmp L8
:   cmp #TYPE_ROUTINE_POINTER
    bne :+
    lda #4
    jmp L8
:   lda #0
    ; Fall through
L8: ldx #0
    jsr storeSize
L9: jsr popAX
    pha
    phx
    jsr popQ
    plx
    pla
    rts
.endproc

; This routine stores A/X on the stack
.proc storeSize
    ldz #sizeOffset
    nop
    sta (stackPointer),z
    inz
    txa
    nop
    sta (stackPointer),z
    rts
.endproc

; Type is in ptr1
.proc getSubtypeSize
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    jsr pushQ
    ldq ptr1
    jsr getTypeSize
    phx
    pha
    jsr popQ
    stq ptr1
    ldz #type::size
    pla
    sta tmp1
    nop
    sta (ptr1),z
    inz
    pla
    nop
    sta (ptr1),z
    tax
    lda tmp1
    rts
.endproc
