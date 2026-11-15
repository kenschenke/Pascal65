;
; sequence.s
; Ken Schenke (kenschenke@gmail.com)
;
; Sound library sequencer: plays a stream of notes and commands on a
; voice, moved on by the raster IRQ
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; A sequence is a stream of bytes in the program's memory (see SEQ_* in
; sound.inc and docs/docs/sound/sequences.md). A note (0-95) or a rest
; is followed by its length in ticks, and a tick is the voice's tempo in
; frames (1 to start with). The commands between them take effect at
; once. The IRQ counts the tick down (tickSeqX), then the ticks, then
; reads up to and through the next note or rest (stepSeqX).
;
; The stream is read with an absolute load whose address is written into
; the code (readByteX), so the IRQ needn't use the zero page. Only the IRQ
; and the main program between sei and plp read it.

.include "runtime.inc"
.include "sound.inc"

.export playSequence, tickSeqX

.import loadVoice, voiceRegs, voiceIdx, voiceReg, arg, seqData
.import ctrlShadow, pwLo, pwHi
.import installIrq, irqWork, doneCount, voiceFlags, voiceFrames, gateOffX
.import calcNoteFreq, playVoice

.bss

; NUM_VOICES each. Only valid while the voice has VF_SEQ.
seqLo: .res NUM_VOICES      ; The next byte
seqHi: .res NUM_VOICES
seqStartLo: .res NUM_VOICES ; The first byte, for SEQ_LOOP
seqStartHi: .res NUM_VOICES
seqTempo: .res NUM_VOICES   ; Frames a tick, 1-255
seqTick: .res NUM_VOICES    ; Frames left in this tick
seqWait: .res NUM_VOICES    ; Ticks left in this note or rest

; Only used between sei and plp, or by the IRQ
seqVoice: .res 1            ; The voice stepSeqX is reading (0-11)
seqLooped: .res 1           ; Nonzero once stepSeqX has looped
seqByte: .res 1

.code

; Procedure PlaySequence(voice : Byte; data : ^Byte);
; A Nil pointer is ignored.
.proc playSequence
    jsr loadVoice
    bcs DN
    lda #1
    jsr rtLibLoadParam
    sta seqData
    stx seqData+1
    ora seqData+1
    beq DN                  ; Branch if Nil
    jsr installIrq
    php
    sei
    ldx voiceIdx
    lda seqData
    sta seqLo,x
    sta seqStartLo,x
    lda seqData+1
    sta seqHi,x
    sta seqStartHi,x
    lda #1
    sta seqTempo,x
    lda #0
    sta voiceFrames,x       ; Not a timed note
    lda #VF_PLAYING|VF_SEQ
    sta voiceFlags,x
    sta irqWork             ; Nonzero
    jsr stepSeqX            ; Starts the first note now
    plp
DN: rts
.endproc

; Moves the sequence on voice X (0-11) one frame. Call it with interrupts
; disabled. Keeps X.
.proc tickSeqX
    dec seqTick,x
    bne DN                  ; Branch if the tick goes on
    lda seqTempo,x
    sta seqTick,x
    dec seqWait,x
    bne DN                  ; Branch if the note goes on
    jmp stepSeqX
DN: rts
.endproc

; Returns the next byte of the sequence on voice X (0-11) in A, with the
; flags set by it, and moves past it. Keeps X and Y.
.proc readByteX
    lda seqLo,x
    sta RD+1
    lda seqHi,x
    sta RD+2
    inc seqLo,x
    bne RD
    inc seqHi,x
RD: lda $ffff               ; The address is written above
    rts
.endproc

; Reads the length of a note or rest on voice X and starts waiting for
; it. A length of 0 is taken as 1. Keeps X.
.proc readWaitX
    jsr readByteX
    bne :+
    lda #1
:   sta seqWait,x
    lda seqTempo,x
    sta seqTick,x
    rts
.endproc

; Reads the sequence on voice X (0-11) through the next note or rest and
; starts it. At the end, or a byte past SEQ_END, the voice stops and its
; gate closes, as at the end of a timed note. Call it with interrupts
; disabled. Keeps X.
.proc stepSeqX
    stx seqVoice
    lda #0
    sta seqLooped
L1: ldx seqVoice
    jsr readByteX
    cmp #NUM_NOTES
    bcs :+
    jmp NT                  ; A note
:   cmp #SEQ_REST
    beq RS
    cmp #SEQ_WAVE
    beq WV
    cmp #SEQ_ENVELOPE
    beq EV
    cmp #SEQ_TEMPO
    beq TP
    cmp #SEQ_PULSE
    beq PW
    cmp #SEQ_LOOP
    beq LP
    jmp EN                  ; SEQ_END or past it

RS: jsr readWaitX
    jmp gateOffX

WV: jsr readByteX           ; Waveform
    and #$f0
    sta seqByte
    lda ctrlShadow,x
    and #$0f
    ora seqByte
    sta ctrlShadow,x
    ldy voiceRegs,x
    sta SID_BASE+SID_CTRL,y
    jmp L1

EV: ldy voiceRegs,x         ; Envelope
    jsr readByteX
    sta SID_BASE+SID_AD,y
    jsr readByteX
    sta SID_BASE+SID_SR,y
    jmp L1

TP: jsr readByteX           ; Tempo
    bne :+
    lda #1
:   sta seqTempo,x
    jmp L1

PW: ldy voiceRegs,x         ; Pulse width
    jsr readByteX
    sta pwLo,x
    sta SID_BASE+SID_PWLO,y
    jsr readByteX
    and #$0f
    sta pwHi,x
    sta SID_BASE+SID_PWHI,y
    jmp L1

LP: lda seqLooped
    bne EN                  ; Branch if no note since the last loop
    inc seqLooped
    lda seqStartLo,x
    sta seqLo,x
    lda seqStartHi,x
    sta seqHi,x
    jmp L1

EN: lda #VF_DONE            ; The end
    sta voiceFlags,x
    inc doneCount
    jmp gateOffX

NT: ldx #0                  ; The note's high byte
    jsr calcNoteFreq        ; Sets freq
    ldx seqVoice
    jsr readWaitX
    stx voiceIdx
    lda voiceRegs,x
    sta voiceReg
    lda #0                  ; Untimed: the sequence times it
    sta arg
    jsr playVoice
    ldx seqVoice
    lda #VF_PLAYING|VF_SEQ  ; playVoice ended the sequence
    sta voiceFlags,x
    rts
.endproc
