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

.import units, setDeclOffsets, fixGlobalOffsets

.bss

; CBM filenames are at most 16 characters (error.s in asmlib)
MAX_FILENAME_LENGTH = 16

offset: .res 2
unit: .res 4
savedFilename: .res MAX_FILENAME_LENGTH+1

.code

; Root offset passed in A/X
.proc setUnitOffsets
    sta offset
    stx offset+1

    ; A unit's errors (errTooManyVariables) are in its own file. Keep the
    ; caller's to put back.
    jsr getCompilerFilename
    sta ptr1
    stx ptr1+1
    ldy #0
:   lda (ptr1),y
    sta savedFilename,y
    beq :+
    iny
    cpy #MAX_FILENAME_LENGTH
    bne :-
    lda #0
    sta savedFilename,y

:   ldq units
    stq unit

L1: ldq unit
    jsr isQZero
    beq L2
    jsr setCompilerUnitFilename

    ; The unit's first slot. icode makes its level 1 offsets relative to
    ; it, and the linker adds it back (LINKADDR_FRAME).
    ldq unit
    stq ptr1
    ldz #unit::firstSlot
    lda offset
    nop
    sta (ptr1),z
    inz
    lda offset+1
    nop
    sta (ptr1),z
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
    jsr tpuSlotsEnd
    pha
    phx

    ; How many slots it has
    ldq unit
    stq ptr1
    plx
    pla
    pha
    sec
    sbc offset
    ldz #unit::slots
    nop
    sta (ptr1),z
    txa
    sbc offset+1
    inz
    nop
    sta (ptr1),z
    pla
    sta offset
    stx offset+1

    ldz #unit::next
    neg
    neg
    nop
    lda (ptr1),z
    stq unit
    bra L1

    ; A unit's table holds the variables of the units it uses (injectUnit).
    ; They get their levels and offsets as the program's do, once every
    ; unit is numbered. Without it they were level 0, offset 0.
L2: lda #<savedFilename
    ldx #>savedFilename
    jsr setCompilerFilename
    ldq units
L3: stq unit
    jsr isQZero
    beq DN
    stq ptr1
    ldz #unit::astRoot
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    jsr fixGlobalOffsets
:   ldq unit
    stq ptr1
    ldz #unit::next
    neg
    neg
    nop
    lda (ptr1),z
    bra L3

DN: rts
.endproc

; A unit loaded from its TPU (tpuload.s) has only its interface, whose
; variables come first (setDeclOffsets.s). Its slots end where its TPU
; says: this routine returns its first slot plus its TPU's count in A/X.
; Any other unit's end, in A/X, is kept.
.proc tpuSlotsEnd
    pha
    phx
    ldq unit
    stq ptr1
    ldz #unit::fromTpu
    nop
    lda (ptr1),z
    bne :+
    plx
    pla
    rts
:   plx
    pla
    ldz #unit::tpuSlots
    nop
    lda (ptr1),z
    clc
    adc offset
    pha
    inz
    nop
    lda (ptr1),z
    adc offset+1
    tax
    pla
    rts
.endproc
