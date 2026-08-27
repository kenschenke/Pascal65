;
; injectSystemUnit.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; injectSystemUnit routine

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export injectSystemUnit

.import units, findUnit

.bss

systemUnit: .res 4
currentUnit: .res 4

.data

strSystem: .asciiz "system"

.code

; This routine injects the system unit into the scope of all other units
; the program is referencing.
.proc injectSystemUnit
    ; First, find the system unit in the list of units.
    lda #<strSystem
    ldx #>strSystem
    ldy #0
    ldz #0
    jsr findUnit
    jsr isQZero
    bne :+
    rts                 ; System unit not found. Nothing else to do.
:   stq systemUnit
    ldq units
    stq currentUnit

    ; Go through the units and add the system unit to the list of
    ; "Uses" declarations.
L1: ldq currentUnit
    jsr isQZero
    bne :+
    jmp L4

    ; See if currentUnit == systemUnit
:   ldx #0
:   lda currentUnit,x
    cmp systemUnit,x
    bne L2
    inx
    cpx #4
    bne :-
    jmp L3

    ; Create the declaration for a uses statement
L2: lda #TYPE_UNIT
    jsr pushA               ; kind
    lda #0
    jsr pushA               ; isConst
    jsr pushQZero           ; subtype
    jsr pushQZero           ; params
    jsr typeCreate
    stq ptr1                ; type in ptr1

    lda #DECL_USES
    jsr pushA               ; kind
    lda #<strSystem
    ldx #>strSystem
    ldy #0
    ldz #0
    jsr pushQ               ; name
    ldq ptr1
    jsr pushQ               ; type
    jsr pushQZero           ; value
    jsr declCreate
    stq ptr4                ; new decl in ptr4

    ; Add the new declaration as the first declaration in the unit
    ldq currentUnit
    stq ptr1                ; current unit decl in ptr1
    ldz #unit::astRoot
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #decl::code
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2                ; stmt in ptr2
    ldz #stmt::decl
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr3                ; first decl in ptr3
    ; Put new decl in place as first decl in unit
    ldz #stmt::decl
    ldx #0
:   lda ptr4,x
    nop
    sta (ptr2),z
    inz
    inx
    cpx #4
    bne :-
    ; Set the new decl's "next" as the original first decl (ptr3)
    ldz #decl::next
    ldx #0
:   lda ptr3,x
    nop
    sta (ptr4),z
    inz
    inx
    cpx #4
    bne :-

L3: ldq currentUnit
    stq ptr1
    ldz #unit::next
    neg
    neg
    nop
    lda (ptr1),z
    stq currentUnit
    jmp L1

L4: rts
.endproc
