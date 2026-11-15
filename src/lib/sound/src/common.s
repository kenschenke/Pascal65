;
; common.s
; Ken Schenke (kenschenke@gmail.com)
;
; Sound library state, parameter helpers, init and cleanup
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "runtime.inc"
.include "sound.inc"

.export initSoundLibrary, cleanupSoundLibrary
.export loadVoice, loadSid, loadByteParam
.export ctrlShadow, resShadow, modeShadow
.export voiceIdx, voiceReg, sidIdx, sidReg, arg, voiceRegs
.export freq, octave, mask, cutoff
.export prod, rem, mulBy, divBy, mBase, newStep, sFrom, sTo, sFrames
.export sDown, sweepIdx, vDepth, seqData
.export saveScratch, restoreScratch

.import initEngine, stopAllVoices

.rodata

; Offset of each voice's registers from SID_BASE. The SIDs are 32 bytes
; apart and a SID's voices 7 bytes apart. Entries 12-15 are the SIDs'
; own offsets, for the filter sweeps (SWEEP_SID in sound.inc).
voiceRegs:
    .byte $00, $07, $0e
    .byte $20, $27, $2e
    .byte $40, $47, $4e
    .byte $60, $67, $6e
    .byte $00, $20, $40, $60

.bss

startbss:
; The SID's registers at offsets $00-$18 are write-only, so the library
; keeps a copy of the ones it changes a part of.
ctrlShadow: .res NUM_VOICES ; Control register ($04) of each voice
resShadow: .res NUM_SIDS    ; Resonance and filter routing ($17)
modeShadow: .res NUM_SIDS   ; Filter mode and volume ($18)

endbss:

; Every variable a routine uses for a moment is here, in one block. The
; IRQ handler uses them too (the sequencer starts notes and the done
; callback can call any routine), so it saves the block first and puts it
; back after (saveScratch, restoreScratch). Variables used only between
; sei and plp, or only by the IRQ, needn't be here.
scratch:
; Set by loadVoice and loadSid
voiceIdx: .res 1            ; Voice number less 1 (0-11)
voiceReg: .res 1            ; Offset of the voice's registers
sidIdx: .res 1              ; SID number less 1 (0-3)
sidReg: .res 1              ; Offset of the SID's registers
arg: .res 1                 ; Set by loadByteParam
; notes.s
freq: .res 2                ; Set by calcNoteFreq
octave: .res 1
; registers.s
mask: .res 1
cutoff: .res 2
; effects.s
prod: .res 3                ; Product, dividend and quotient
rem: .res 1
mulBy: .res 1
divBy: .res 1
mBase: .res 2
newStep: .res 3
sFrom: .res 2
sTo: .res 2
sFrames: .res 1
sDown: .res 1
sweepIdx: .res 1
vDepth: .res 1
; sequence.s
seqData: .res 2
endScratch:

SCRATCH_SIZE = endScratch - scratch
.assert SCRATCH_SIZE <= 128, error, "scratch is over 128 bytes"

scratchSave: .res SCRATCH_SIZE

.code

; Loads parameter 0, a voice number 1-12. Sets voiceIdx, voiceReg, sidIdx
; and sidReg and returns with the carry clear. A number out of range
; returns with the carry set.
.proc loadVoice
    lda #0
    jsr rtLibLoadParam
    sec
    sbc #1                  ; Voice 0 becomes $ff
    cmp #NUM_VOICES
    bcs DN                  ; Branch if out of range
    sta voiceIdx
    tax
    lda voiceRegs,x
    sta voiceReg
    and #$60                ; The SID's offset is the voice's, less 0-14
    jmp setSid
DN: rts
.endproc

; Loads parameter 0, a SID number 1-4. Sets sidIdx and sidReg and returns
; with the carry clear. A number out of range returns with the carry set.
.proc loadSid
    lda #0
    jsr rtLibLoadParam
    sec
    sbc #1                  ; SID 0 becomes $ff
    cmp #NUM_SIDS
    bcs DN                  ; Branch if out of range
    asl a                   ; Times 32
    asl a
    asl a
    asl a
    asl a
    jmp setSid
DN: rts
.endproc

; Stores the SID offset in A to sidReg and its number less 1 to sidIdx.
; Returns with the carry clear.
.proc setSid
    sta sidReg
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    sta sidIdx
    clc
    rts
.endproc

; Copies the scratch variables to scratchSave. Only the IRQ handler calls
; it, and restoreScratch after.
.proc saveScratch
    ldx #SCRATCH_SIZE-1
:   lda scratch,x
    sta scratchSave,x
    dex
    bpl :-
    rts
.endproc

.proc restoreScratch
    ldx #SCRATCH_SIZE-1
:   lda scratchSave,x
    sta scratch,x
    dex
    bpl :-
    rts
.endproc

; Loads the Byte parameter numbered in A into arg (and A)
.proc loadByteParam
    jsr rtLibLoadParam
    sta arg
    rts
.endproc

; Clears the library's state and the four SIDs, and sets each SID's
; volume to 15. That also stops anything BASIC 65 left playing.
.proc initSoundLibrary
    ldx #endbss-startbss-1
    lda #0
:   sta startbss,x
    dex
    bpl :-
    jsr initEngine

    ldx #NUM_SIDS-1
    lda #15
:   sta modeShadow,x
    dex
    bpl :-

    ; Zero registers $00-$17 of every SID and set $18 to volume 15
    ldx #0
L1: txa
    and #$1f
    cmp #SID_MODEVOL
    beq VL                  ; Branch if the volume register
    bcs NX                  ; Branch if a register past it
    lda #0
    beq WR
VL: lda #15
WR: sta SID_BASE,x
NX: inx
    cpx #NUM_SIDS*SID_SIZE
    bne L1
    rts
.endproc

; Stops every voice and sets every SID's volume to 0, so a program that
; ends during a note doesn't leave it sounding.
.proc cleanupSoundLibrary
    jsr stopAllVoices

    ldx #NUM_SIDS-1
L2: lda #0
    sta modeShadow,x
    txa
    asl a
    asl a
    asl a
    asl a
    asl a
    tay
    lda #0
    sta SID_BASE+SID_MODEVOL,y
    dex
    bpl L2
    rts
.endproc
