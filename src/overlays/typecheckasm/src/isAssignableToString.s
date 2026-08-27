;
; isAssignableToString.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

rightTypeOffset = 0
rightKindOffset = 4

.export isAssignableToString

.import loadStackValue

; This routine sets the Z flag if the type is assignable to a string.
.proc isAssignableToString
    ldz #rightKindOffset
    nop
    lda (stackPointer),z
    cmp #TYPE_ARRAY
    bne L1

    ; Array. Check if the element type is character.
    ldz #rightTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_CHARACTER
    bra L2

    ; Not an array, but could be other compatible type
L1: cmp #TYPE_STRING_VAR
    beq L2
    cmp #TYPE_STRING_LITERAL
    beq L2
    cmp #TYPE_STRING_OBJ
    beq L2
    cmp #TYPE_CHARACTER

L2: php
    jsr popQ
    jsr popA
    plp
    rts
.endproc
