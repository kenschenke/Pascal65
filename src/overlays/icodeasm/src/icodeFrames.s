;
; icodeFrames.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; A module's level 1 frame: the slots it owns in the program's global
; stack frame. The program's come first, then each unit's and library's,
; in the units list's order, which is the order the startup pushes them
; (icodeUnitDeclarations.s). The resolver numbers every level 1 slot from
; the program's first (setUnitOffsets.s), and records each unit's first
; slot and count.
;
; A variable operand names its frame (icode.inc): 0 for this module's,
; or a unit's in the frames table, which follows the imports table. Its
; offset is relative to the frame's first slot. Code generation writes it
; with a LINKADDR_FRAME relocation, and the linker adds the first slot,
; which it works out from the slot counts. A unit compiled on its own
; then needs no base it can't know.

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export writeFrames, frameOf

.import units

.bss

thisUnit: .res 4
frameNum: .res 1
writing: .res 1             ; zero while counting, non-zero while writing
offset: .res 1              ; for frameOf
first: .res 2
count: .res 2
savedPtrs: .res 8           ; ptr1 and ptr2
nameLen: .res 1
nameBuf: .res 13

.code

; This routine writes the frames table to the current output: a count,
; then each unit with slots, in the units list's order: its name (its
; length, then its characters) and its slot count (a word).
.proc writeFrames
    lda #0
    sta writing
    jsr walk
    lda frameNum
    jsr CHROUT
    inc writing
    ; Fall through
.endproc

; This routine counts the frames in frameNum, or writes each one
.proc walk
    lda #0
    sta frameNum
    ldq units
L1: stq thisUnit
    jsr isQZero
    bne :+
    rts

:   jsr loadSlots
    lda count
    ora count+1
    beq NX
    inc frameNum
    lda writing
    beq NX

    ; The name, copied first: CHROUT may change Z
    ldq thisUnit
    stq ptr1
    ldx #0
    ldz #unit::name
:   nop
    lda (ptr1),z
    beq :+
    sta nameBuf,x
    inz
    inx
    cpx #12                     ; unit::name holds 12 and a zero
    bne :-
:   stx nameLen
    txa
    jsr CHROUT
    ldx #0
:   cpx nameLen
    beq :+
    lda nameBuf,x
    jsr CHROUT
    inx
    bra :-
:   lda count
    jsr CHROUT
    lda count+1
    jsr CHROUT

NX: jsr nextUnit
    bra L1
.endproc

; This routine loads the first slot and the slot count of the unit in
; thisUnit into first and count. It changes ptr1.
.proc loadSlots
    ldq thisUnit
    stq ptr1
    ldz #unit::firstSlot
    nop
    lda (ptr1),z
    sta first
    inz
    nop
    lda (ptr1),z
    sta first+1
    ldz #unit::slots
    nop
    lda (ptr1),z
    sta count
    inz
    nop
    lda (ptr1),z
    sta count+1
    rts
.endproc

; This routine returns the unit after thisUnit in Q. It changes ptr1.
.proc nextUnit
    ldq thisUnit
    stq ptr1
    ldz #unit::next
    neg
    neg
    nop
    lda (ptr1),z
    rts
.endproc

; This routine finds the frame of the level 1 slot whose offset (from the
; program's first slot) is in A. It returns the frame's number in X, 0 for
; the program's, and the offset in the frame in A. It keeps ptr1 and ptr2.
.proc frameOf
    sta offset
    ldx #7
:   lda ptr1,x
    sta savedPtrs,x
    dex
    bpl :-

    lda #0
    sta frameNum
    ldq units
L1: stq thisUnit
    jsr isQZero
    beq PR
    jsr loadSlots
    lda count
    ora count+1
    beq NX
    inc frameNum

    ; first <= offset < first + count
    lda first+1
    bne NX
    lda offset
    cmp first
    bcc NX
    sec
    sbc first
    sta offset
    lda count+1
    bne FN
    lda offset
    cmp count
    bcc FN
    clc                         ; Past this frame: put the offset back
    adc first
    sta offset
NX: jsr nextUnit
    bra L1

    ; The program's own
PR: lda #0
    sta frameNum

FN: ldx #7
:   lda savedPtrs,x
    sta ptr1,x
    dex
    bpl :-
    lda offset
    ldx frameNum
    rts
.endproc
