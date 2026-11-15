;
; engine.s
; Ken Schenke (kenschenke@gmail.com)
;
; Sound library IRQ engine: the per-voice state and the raster IRQ
; handler that times notes
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "runtime.inc"
.include "c64.inc"
.include "sound.inc"

.export initEngine, installIrq, stopVoiceX, stopAllVoices
.export voiceFlags, voiceFrames, irqWork

.import ctrlShadow, voiceRegs

.bss

startbss:
irqInstalled: .res 1        ; Nonzero once the handler is in the chain
irqWork: .res 1             ; Nonzero when a voice has work for the IRQ
voiceFlags: .res NUM_VOICES ; VF_* bits of each voice
voiceFrames: .res NUM_VOICES ; Frames left of a timed note, 0 if untimed
endbss:

.assert endbss-startbss <= 256, error, "engine BSS is over 256 bytes"

.code

; Clears the engine's state. The handler isn't in the chain: the runtime
; puts the KERNAL's IRQ vector back when a program ends, so a program run
; again from memory starts without it.
.proc initEngine
    ldx #endbss-startbss-1
    lda #0
:   sta startbss,x
    dex
    cpx #$ff
    bne :-
    rts
.endproc

; Stops voice X (0-11): clears its state and closes its gate, so its
; release plays. Keeps X.
.proc stopVoiceX
    php
    sei
    lda #0
    sta voiceFlags,x
    sta voiceFrames,x
    lda ctrlShadow,x
    and #<~CTRL_GATE
    sta ctrlShadow,x
    ldy voiceRegs,x
    sta SID_BASE+SID_CTRL,y
    plp
    rts
.endproc

; Stops all 12 voices
.proc stopAllVoices
    ldx #NUM_VOICES-1
:   jsr stopVoiceX
    dex
    bpl :-
    rts
.endproc

; Adds the handler to the IRQ chain, the first time it's called. The
; handler can't load its own address with #<label (the library is
; relocated), so getIrqAddress puts it on the CPU stack with a JSR.
installIrq:
    lda irqInstalled
    bne DN
    jmp getIrqAddress
setIrq:
    pla                     ; The JSR's return address, plus 1, is
    clc                     ; irqHandler
    adc #1
    sta irqInstalled        ; Low byte, for a moment
    pla
    adc #0
    tax
    lda irqInstalled

    ldy #%00000001          ; The raster interrupt

    sei
    jsr rtAddIrqHandler
    sta irqReturn+1
    stx irqReturn+2
    lda #1
    sta irqInstalled
    cli
DN: rts

getIrqAddress:
    jsr setIrq
    ; irqHandler must be the very next line
; Runs once a frame, on the raster interrupt. It counts down each timed
; note and closes the voice's gate when it runs out. It doesn't touch the
; zero page or call the runtime, because it can interrupt either.
irqHandler:
    lda irqWork
    beq irqReturn           ; Branch if no voice needs it
    lda VIC_IRR
    lsr a
    bcc irqReturn           ; Branch if not the raster interrupt

    lda #0
    sta irqWork
    ldx #NUM_VOICES-1
L1: lda voiceFrames,x
    beq NX                  ; Branch if not a timed note
    dec voiceFrames,x
    bne MR                  ; Branch if the note has frames left
    lda voiceFlags,x
    and #<~VF_PLAYING
    sta voiceFlags,x
    lda ctrlShadow,x        ; Close the gate
    and #<~CTRL_GATE
    sta ctrlShadow,x
    ldy voiceRegs,x
    sta SID_BASE+SID_CTRL,y
    jmp NX
MR: inc irqWork
NX: dex
    bpl L1

irqReturn:
    jmp $0000
