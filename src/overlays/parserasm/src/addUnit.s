.include "ast.inc"
.include "asmlib.inc"
.include "astlib.inc"
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
    bne L2
    stq ptr1
    ldz #unit::name
    neg
    neg
    nop
    lda (ptr1),z
    jsr isUnitNameEqual
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
    bne L3
    stq ptr1
    ldz #unit::next
    ldx #0
:   lda ptr1,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    bra L4
L3: stq units

L4: ; declCreate
    lda #TYPE_UNIT
    jsr pushA
    lda #0
    jsr pushA
    jsr pushQZero
    jsr pushQZero
    jsr typeCreate
    stq declType
    ldz #nameOffset+1
    nop
    lda (stackPointer),z
    tax
    dez
    nop
    lda (stackPointer),z
    jsr nameCreate
    stq ptr1
    lda #DECL_USES
    jsr pushA
    ldq ptr1
    jsr pushQ
    ldq declType
    jsr pushQ
    jsr pushQZero
    jsr declCreate
    stq ptr2
    jsr appendDecl

    jsr popQ
    jsr popQ
    jsr popAX
    ldq ptr2
    rts
.endproc

; This routine compares the unit name, in Q to the name passed to addUnit.
; If they are equal, the Z flag is set.
.proc isUnitNameEqual
    stq ptr3
    ldz #nameOffset
    neg
    lda (stackPointer),z
    sta ptr2
    inz
    nop
    lda (stackPointer),z
    sta ptr2+1

    ldz #0
    ldy #0
L1: nop
    lda (ptr3),z
    cmp (ptr2),y
    bne L2
    lda (ptr2),y
    bne L2
    iny
    inz
    bra L2
L2: rts
.endproc
