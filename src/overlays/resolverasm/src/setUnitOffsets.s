;
; setUnitOffsets.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; setUnitOffsets routine

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export setUnitOffsets

.import units, setDeclOffsets

.bss

offset: .res 2
unit: .res 4

.code

; Root offset passed in A/X
.proc setUnitOffsets
    sta offset
    stx offset+1

    ldq units
    stq unit

L1: ldq unit
    jsr isQZero
    beq L2

    stq ptr1
    ldz #unit::astRoot
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    lda offset
    ldx offset+1
    jsr pushAX
    lda #0
    jsr pushA
    jsr setDeclOffsets
    sta offset
    stx offset+1

    ldq unit
    stq ptr1
    ldz #unit::next
    neg
    neg
    nop
    lda (ptr1),z
    stq unit
    bra L1

L2: rts
.endproc
