;
; getRecordSize.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; getRecordSize routine

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export getRecordSize

.import getTypeSize

declOffset = 0
sizeOffset = 4

; Type is in ptr1
.proc getRecordSize
    ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ

L1: jsr getDeclPtr
    jsr isQZero
    beq L2
    stq ptr2
    ldz #decl::type
    neg
    neg
    nop
    lda (ptr2),z
    jsr getTypeSize
    sta tmp1
    stx tmp2
    ldz #sizeOffset
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
    
    jsr getDeclPtr
    stq ptr2
    ldz #decl::next
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    ldz #declOffset
    ldx #0
:   lda ptr2,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    bra L1

L2: jsr popQ
    rts
.endproc

.proc getDeclPtr
    ldz #declOffset
    neg
    neg
    nop
    lda (stackPointer),z
    rts
.endproc
