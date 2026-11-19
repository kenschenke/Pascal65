;
; addModuleUnit.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; addModuleUnit routine

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export addModuleUnit

.import units

.bss

rootPtr: .res 4
newUnit: .res 4
lastUnit: .res 4
unitName: .res 13           ; unitCreate takes it from 16-bit memory

.code

; This routine adds a unit compiled on its own (unit mode), its root in Q,
; to the end of the units list, after the units its Uses add, so it is
; resolved, numbered, type checked and written to icode as in a program
; compile (orderUnits puts it after the units it uses). Call it after
; injectSystemUnit: the parser gave the unit a Uses of System, as it gives
; the first module it parses, and injectSystemUnit gives every unit in the
; list another, which injected System's interface twice.
.proc addModuleUnit
    stq rootPtr
    stq ptr1
    ldz #decl::name
    ldx #0
:   nop
    lda (ptr1),z
    sta unitName,x
    beq :+
    inz
    inx
    cpx #12
    bne :-
    lda #0
    sta unitName,x
:   lda #<unitName
    ldx #>unitName
    jsr unitCreate
    stq newUnit
    stq ptr1
    ldz #unit::astRoot
    ldx #0
:   lda rootPtr,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-

    ; At the end of the list
    ldq units
    jsr isQZero
    bne :+
    ldq newUnit
    stq units
    rts
:   stq lastUnit
L1: ldq lastUnit
    stq ptr1
    ldz #unit::next
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L2
    stq lastUnit
    bra L1
L2: ldz #unit::next
    ldx #0
:   lda newUnit,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    rts
.endproc
