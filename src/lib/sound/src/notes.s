;
; notes.s
; Ken Schenke (kenschenke@gmail.com)
;
; Sound library routines that play timed notes
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "runtime.inc"
.include "sound.inc"

.export noteFreq, playNote, playFreq, isPlaying, stopVoice
.export frameRate, calcNoteFreq, returnAX, playVoice

.import loadVoice, loadByteParam
.import ctrlShadow, voiceIdx, voiceReg, arg, freq, octave
.import installIrq, stopVoiceX, setVoiceFreq
.import voiceFlags, voiceFrames, irqWork

.rodata

; The SID frequency of each note of octave 6 (C6 to B6, A4 = 440 Hz).
; NoteFreq shifts it right for a lower octave and left for octave 7. The
; SIDs run from the video clock, so PAL and NTSC need a table each.
palNotes:
    .word $459c, $49c0, $4e23, $52c8, $57b4, $5ceb
    .word $6272, $684c, $6e80, $7512, $7c08, $8368
ntscNotes:
    .word $430f, $470c, $4b46, $4fbf, $547d, $5984
    .word $5ed6, $647a, $6a73, $70c8, $777d, $7e97

.code

; Sets freq to the SID frequency of the note in A/X (0-95, C0 to B7) and
; returns with the carry clear. A bad note returns with the carry set.
; B7 is past the highest SID frequency on PAL, so it's $FFFF there.
.proc calcNoteFreq
    cpx #0
    bne BD                  ; Branch if over 255
    cmp #NUM_NOTES
    bcs BD                  ; Branch if over 95
    ldy #0                  ; The octave
:   cmp #12
    bcc :+
    sbc #12                 ; The carry is set
    iny
    bne :-
:   sty octave
    asl a                   ; The semitone's word in the table
    bit VIC_PAL
    bpl :+                  ; Branch if PAL
    adc #ntscNotes-palNotes ; The carry is clear (the asl)
:   tax
    lda palNotes,x
    sta freq
    lda palNotes+1,x
    sta freq+1

    lda octave
    cmp #7
    bne LO                  ; Branch if octave 6 or lower
    asl freq
    rol freq+1
    bcc OK                  ; Branch if it fits
    lda #$ff
    sta freq
    sta freq+1
    bne OK

LO: lda #6                  ; Shift right 6 - octave times
    sec
    sbc octave
    beq OK                  ; Branch if octave 6
    tay
:   lsr freq+1
    ror freq
    dey
    bne :-
    lda freq                ; Round: add the last bit shifted out
    adc #0
    sta freq
    lda freq+1
    adc #0
    sta freq+1
OK: clc
    rts
BD: sec
    rts
.endproc

; Function NoteFreq(note : Word) : Word;
.proc noteFreq
    lda #0
    jsr rtLibLoadParam
    jsr calcNoteFreq
    bcc :+                  ; Branch if a good note
    lda #0
    sta freq
    sta freq+1
:   lda freq
    ldx freq+1
    jmp returnAX
.endproc

; Returns A/X from a library function, with the high word zero
.proc returnAX
    ldy #0
    sty sreg
    sty sreg+1
    jmp rtLibReturnValue
.endproc

; Procedure PlayNote(voice : Byte; note : Word; frames : Byte);
.proc playNote
    jsr loadVoice
    bcs DN
    lda #1
    jsr rtLibLoadParam
    jsr calcNoteFreq
    bcs DN                  ; Branch if a bad note
    jmp startNote
DN: rts
.endproc

; Procedure PlayFreq(voice : Byte; freq : Word; frames : Byte);
.proc playFreq
    jsr loadVoice
    bcs DN
    lda #1
    jsr rtLibLoadParam
    sta freq
    stx freq+1
    jmp startNote
DN: rts
.endproc

; Plays freq on voice voiceIdx for the frames in parameter 2 (0 until
; it's stopped)
.proc startNote
    lda #2
    jsr loadByteParam
    jsr installIrq
    ; Fall through to playVoice
.endproc

; Plays freq on voice voiceIdx (with voiceReg) for arg frames (0 until
; it's stopped). The gate closes and opens again, so the attack starts
; over if the voice was playing. It ends a frequency sweep on the voice
; and starts its vibrato over (setVoiceFreq), and ends its sequence.
; The sequencer calls it from the IRQ.
.proc playVoice
    jsr setVoiceFreq
    php
    sei
    ldx voiceIdx
    ldy voiceReg
    lda ctrlShadow,x
    and #<~CTRL_GATE
    sta SID_BASE+SID_CTRL,y

    ; The envelope sees the gate once a SID clock (about 1 MHz), so keep
    ; it closed for a few microseconds at 40 MHz or the attack won't start
    ; over.
    ldy #GATE_DELAY
:   dey
    bne :-
    ldy voiceReg

    lda ctrlShadow,x
    ora #CTRL_GATE
    sta ctrlShadow,x
    sta SID_BASE+SID_CTRL,y
    lda arg
    sta voiceFrames,x
    beq :+                  ; Branch if untimed
    sta irqWork
:   lda #VF_PLAYING         ; Ends a sequence (VF_SEQ)
    sta voiceFlags,x
    plp
    rts
.endproc

; Function IsPlaying(voice : Byte) : Boolean;
.proc isPlaying
    jsr loadVoice
    lda #0
    bcs RT                  ; Branch if a bad voice
    ldx voiceIdx
    lda voiceFlags,x
    and #VF_PLAYING
RT: ldx #0
    jmp returnAX
.endproc

; Procedure StopVoice(voice : Byte);
.proc stopVoice
    jsr loadVoice
    bcs DN
    ldx voiceIdx
    jmp stopVoiceX
DN: rts
.endproc

; Function FrameRate : Byte;
.proc frameRate
    lda #50
    bit VIC_PAL
    bpl :+                  ; Branch if PAL
    lda #60
:   ldx #0
    jmp returnAX
.endproc
