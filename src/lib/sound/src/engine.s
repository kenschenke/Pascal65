;
; engine.s
; Ken Schenke (kenschenke@gmail.com)
;
; Sound library IRQ engine: the per-voice state, the raster IRQ handler
; that times notes and runs sequences, and the done callback
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "runtime.inc"
.include "c64.inc"
.include "sound.inc"

.export initEngine, installIrq, stopVoiceX, stopAllVoices, gateOffX
.export voiceFlags, voiceFrames, irqWork, doneCount
.export setSoundDoneCallback, clearSoundDoneCallback

.import ctrlShadow, voiceRegs, saveScratch, restoreScratch
.import initEffects, stopEffectsX, stopFilterSweeps, runEffects
.import tickSeqX

.bss

startbss:
irqInstalled: .res 1        ; Nonzero once the handler is in the chain
irqWork: .res 1             ; Nonzero when a voice has work for the IRQ
voiceFlags: .res NUM_VOICES ; VF_* bits of each voice
voiceFrames: .res NUM_VOICES ; Frames left of a timed note, 0 if untimed
doneCount: .res 1           ; Nonzero if a voice has VF_DONE
doneCb: .res 4              ; The done callback, 0 if none
endbss:

.assert endbss-startbss <= 256, error, "engine BSS is over 256 bytes"

globalFrame: .res 2         ; The program's stack frame (stackP at init)

; Only used by the IRQ
doneVoice: .res 1           ; The voice the callback is called for (0-11)
zpSave: .res ZP_SAVE_SIZE   ; The runtime's zero page, during the callback

.assert ZP_SAVE_SIZE <= 128, error, "zero page save is over 128 bytes"

; The callback's stack frame starts this many bytes below the runtime
; stack pointer, so it can't change a value the interrupted code has just
; popped and is still reading
CB_STACK_GAP = 32

.code

; Clears the engine's state. The handler isn't in the chain: the runtime
; puts the KERNAL's IRQ vector back when a program ends, so a program run
; again from memory starts without it. The program calls the library's
; init with stackP at its own stack frame, which never moves, so it's
; kept for the done callback.
.proc initEngine
    lda stackP
    sta globalFrame
    lda stackP+1
    sta globalFrame+1
    ldx #endbss-startbss-1
    lda #0
:   sta startbss,x
    dex
    cpx #$ff
    bne :-
    jmp initEffects
.endproc

; Closes the gate of voice X (0-11). Call it with interrupts disabled.
; Keeps X.
.proc gateOffX
    lda ctrlShadow,x
    and #<~CTRL_GATE
    sta ctrlShadow,x
    ldy voiceRegs,x
    sta SID_BASE+SID_CTRL,y
    rts
.endproc

; Stops voice X (0-11): clears its state, ends its sequence and effects
; and closes its gate, so its release plays. It doesn't call the done
; callback. Keeps X.
.proc stopVoiceX
    php
    sei
    lda #0
    sta voiceFlags,x
    sta voiceFrames,x
    jsr gateOffX
    jsr stopEffectsX
    plp
    rts
.endproc

; Stops all 12 voices and the filter sweeps
.proc stopAllVoices
    ldx #NUM_VOICES-1
:   jsr stopVoiceX
    dex
    bpl :-
    jmp stopFilterSweeps
.endproc

; Procedure ClearSoundDoneCallback;
.proc clearSoundDoneCallback
    lda #0
    tax
    sta sreg
    sta sreg+1
    beq ::storeDoneCb       ; Always
.endproc

; Procedure SetSoundDoneCallback(callback : SoundDoneCb);
.proc setSoundDoneCallback
    lda #0
    jsr rtLibLoadParam
    ; Fall through to storeDoneCb
.endproc

; Stores A/X/sreg in doneCb
.proc storeDoneCb
    php
    sei
    sta doneCb
    stx doneCb+1
    lda sreg
    sta doneCb+2
    lda sreg+1
    sta doneCb+3
    plp
    rts
.endproc

; Pushes the done callback's pointer, with its nesting level, on the
; runtime stack
.proc pushDoneCb
    lda doneCb+2
    sta sreg
    lda doneCb+3
    sta sreg+1
    lda doneCb
    ldx doneCb+1
    jmp rtPushEax
.endproc

; Calls the done callback for voice doneVoice, from the IRQ. Like any
; library calling a Pascal routine, it pops the parameter and the stack
; frame after: rtLibCallRoutine leaves the caller's nesting level on the
; CPU stack for rtLibStackCleanup, so neither call can be a JMP.
;
; The routine's static link, which it reaches the program's variables
; by, is worked out from stackP and currentNestingLevel. The IRQ may have
; stopped the program between setting one and the other (on a call or a
; return), so they are set to the program's frame and level first. That
; is why the callback must be declared at the program's outer level. The
; caller saved the zero page and puts it back after.
.proc callDoneCb
    sec
    lda sp
    sbc #CB_STACK_GAP
    sta sp
    lda sp+1
    sbc #0
    sta sp+1
    lda globalFrame
    sta stackP
    lda globalFrame+1
    sta stackP+1
    lda #1                  ; The program's nesting level
    sta currentNestingLevel
    jsr pushDoneCb
    jsr rtLibStackHeader
    ldx doneVoice
    inx                     ; Voices are 1-12
    txa
    ldx #0
    stx sreg
    stx sreg+1
    jsr rtPushEax
    jsr pushDoneCb
    jsr rtLibCallRoutine
    jsr rtPopEax            ; The parameter
    lda #0                  ; A procedure
    jsr rtLibStackCleanup
    rts
.endproc

; Clears VF_DONE of each voice that has it and calls the done callback
; for it, if there is one. The callback is Pascal code, which uses the
; runtime's zero page, so it is saved first: the IRQ may have stopped the
; program in the middle of using it.
.proc runDone
    lda doneCount
    beq DN                  ; Branch if no voice ended
    lda #0
    sta doneCount
    ldx #ZP_SAVE_SIZE-1
:   lda ZP_SAVE_START,x
    sta zpSave,x
    dex
    bpl :-
    ldx #NUM_VOICES-1
L1: lda voiceFlags,x
    and #VF_DONE
    beq NX                  ; Branch if the voice didn't end
    lda voiceFlags,x
    and #<~VF_DONE
    sta voiceFlags,x
    lda doneCb
    ora doneCb+1
    beq NX                  ; Branch if no callback
    stx doneVoice
    jsr callDoneCb
    ldx doneVoice
NX: dex
    bpl L1
    ldx #ZP_SAVE_SIZE-1
:   lda zpSave,x
    sta ZP_SAVE_START,x
    dex
    bpl :-
DN: rts
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
; note and closes the voice's gate when it runs out, moves each sequence
; on (tickSeqX), runs the effects (runEffects) and calls the done
; callback for each voice that ended (runDone). The program may have been
; in the middle of a library routine, so it saves the library's scratch
; variables first. Only the done callback touches the zero page or calls
; the runtime.
irqHandler:
    lda irqWork
    beq irqReturn           ; Branch if no voice needs it
    lda VIC_IRR
    lsr a
    bcc irqReturn           ; Branch if not the raster interrupt

    jsr saveScratch
    lda #0
    sta irqWork
    ldx #NUM_VOICES-1
L1: lda voiceFrames,x
    beq SQ                  ; Branch if not a timed note
    dec voiceFrames,x
    bne MR                  ; Branch if the note has frames left
    lda #VF_DONE            ; The note ended
    sta voiceFlags,x
    inc doneCount
    jsr gateOffX
    jmp NX
SQ: lda voiceFlags,x
    and #VF_SEQ
    beq NX                  ; Branch if not playing a sequence
    jsr tickSeqX
    lda voiceFlags,x
    and #VF_SEQ
    beq NX                  ; Branch if the sequence ended
MR: inc irqWork
NX: dex
    bpl L1
    jsr runEffects
    jsr runDone
    jsr restoreScratch

irqReturn:
    jmp $0000
