;
; isAssignmentCompatible.s
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
leftKindOffset = rightTypeOffset + 4

.export isAssignmentCompatible

.import isTypeInteger, loadStackValue

.bss

rightKind: .res 1

.code

; On exit, the Z flag is set if the assignment is compatible.
.proc isAssignmentCompatible
    ldz #rightTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    sta rightKind
    ldz #leftKindOffset
    nop
    lda (stackPointer),z
    cmp rightKind
    bne :+
    lda #0
    bra DN

:   jsr isTypeInteger       ; left kind is still in A
    bne NO
    lda rightKind
    jsr isTypeInteger
    bne NO
    lda #0
    bra DN

NO: lda #1
DN: pha
    jsr popQ
    jsr popA
    pla
    rts
.endproc
