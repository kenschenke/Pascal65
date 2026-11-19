;
; addUnit.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Add a unit to the list of units used by the program

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

lastDeclOffset = 0
firstDeclOffset = 4
nameOffset = 8

.export addUnit

.import units, parserValue, appendDecl

.bss

lastUnit: .res 4
thisUnit: .res 4
declType: .res 4

.code

.proc addUnit
    lda #0
    tax
    tay
    taz
    stq lastUnit

    ldq units
    stq thisUnit

L1: ldq thisUnit
    jsr isQZero
    beq L2
    stq ptr1
    jsr isUnitNameEqual     ; the unit in Q; its name is its first member
    beq L2
    ldq thisUnit
    stq lastUnit
    ldz #unit::next
    neg
    neg
    nop
    lda (ptr1),z
    stq thisUnit
    bra L1

L2: ldq thisUnit
    jsr isQZero
    bne L4
    ; Add this unit to the list
    ldz #nameOffset+1
    nop
    lda (stackPointer),z
    tax
    dez
    nop
    lda (stackPointer),z
    jsr unitCreate
    stq thisUnit
    ldq lastUnit
    jsr isQZero
    beq L3
    stq ptr1
    ldz #unit::next
    ldx #0
:   lda thisUnit,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    bra L4
L3: ldq thisUnit
    stq units

L4: ; declCreate
    lda #TYPE_UNIT
    jsr pushA               ; kind
    lda #0
    jsr pushA               ; const
    jsr pushQZero           ; subtype
    jsr pushQZero           ; params
    jsr typeCreate
    stq declType
    ldz #nameOffset+1
    nop
    lda (stackPointer),z
    tax
    dez
    nop
    lda (stackPointer),z
    ldy #0
    ldz #0
    stq ptr1
    lda #DECL_USES          ; kind
    jsr pushA
    ldq ptr1                ; name
    jsr pushQ
    ldq declType            ; type
    jsr pushQ
    jsr pushQZero           ; value
    jsr declCreate
    stq ptr2
    jsr appendDecl

    ldq units
    jsr isQZero
    bne :+
    ldq ptr2
    stq units

:   jsr popQ
    jsr popQ
    jsr popAX
    ldq ptr2
    rts
.endproc

; This routine compares the name of the unit in Q (unit::name, its first
; member) with the name passed to addUnit, a pointer in bank 0. The Z flag
; is set if they are equal. It once took the name's first four bytes as
; the pointer and returned after one byte, so it never matched, and a
; unit named twice was added twice.
.proc isUnitNameEqual
    stq ptr3
    ldz #nameOffset
    nop
    lda (stackPointer),z
    sta ptr2
    inz
    nop
    lda (stackPointer),z
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3

    ldz #0
L1: nop
    lda (ptr3),z
    beq L2                  ; The end of the unit's name
    nop
    cmp (ptr2),z
    bne L3
    inz
    bne L1

    ; The names are equal if the other one ends here too
L2: nop
    lda (ptr2),z
L3: rts
.endproc
