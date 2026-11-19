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
.include "icode.inc"
.include "4510macros.inc"

.export writeFrames, frameOf, writeModule

.import units, operand1, icodeWriteInstruction

.bss

thisUnit: .res 4
frameNum: .res 1
moduleFrame: .res 1          ; the frame of the module whose code this is
writing: .res 1             ; zero while counting, non-zero while writing
offset: .res 1              ; for frameOf
first: .res 2
count: .res 2
savedPtrs: .res 8           ; ptr1 and ptr2
target: .res 4              ; for writeModule
nameLen: .res 1
nameBuf: .res 13

.code

; This routine writes the frames table to the current output: a count,
; then each unit with slots, in the units list's order: its name (its
; length, then its characters) and its slot count (a word).
.proc writeFrames
    lda #0
    sta moduleFrame
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
; the module's own (writeModule), and the offset in the frame in A. It
; keeps ptr1 and ptr2.
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

    ; The module's own is frame 0
FN: lda frameNum
    cmp moduleFrame
    bne :+
    lda #0
    sta frameNum
:   ldx #7
:   lda savedPtrs,x
    sta ptr1,x
    dex
    bpl :-
    lda offset
    ldx frameNum
    rts
.endproc

; This routine writes MDL, which starts the code of the module in Q: a
; unit, or zero for the program. Its operand is the module's frame in the
; frames table, or 0 for the program or a unit with no slots. It writes
; nothing if that is the frame already in effect, which at first is 0.
; Until the next MDL, frame 0 is that module's (frameOf), so a unit's
; code names its own variables as its own icode file will. Code
; generation relocates them against the frame MDL names. It changes ptr1.
.proc writeModule
    stq thisUnit
    jsr isQZero
    beq L3
    stq target

    ; Count the frames up to the unit's
    lda #0
    sta frameNum
    ldq units
L1: stq thisUnit
    jsr isQZero
    beq L3                      ; not in the list
    jsr loadSlots
    lda count
    ora count+1
    beq L2
    inc frameNum
L2: ldx #3
:   lda thisUnit,x
    cmp target,x
    bne :+
    dex
    bpl :-
    lda count                   ; the unit: frame 0 if it has no slots
    ora count+1
    bne L4
    bra L3
:   jsr nextUnit
    bra L1

L3: lda #0
    sta frameNum
L4: lda frameNum
    cmp moduleFrame
    bne :+
    rts                         ; no change
:   sta moduleFrame
    lda #IC_IBU
    sta operand1
    lda frameNum
    sta operand1+1
    lda #IC_MDL
    jmp icodeWriteInstruction
.endproc
