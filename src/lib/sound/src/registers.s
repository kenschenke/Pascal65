;
; registers.s
; Ken Schenke (kenschenke@gmail.com)
;
; Sound library routines that set the SID registers
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "runtime.inc"
.include "sound.inc"

.export setSidMode, setVolume, setWaveform, setEnvelope, setFrequency
.export setPulseWidth, setGate, setRingMod, setSync, setFilter
.export filterVoice, getOsc3, getEnv3

.import loadVoice, loadSid, loadByteParam
.import ctrlShadow, resShadow, modeShadow
.import voiceIdx, voiceReg, sidIdx, sidReg, arg
.import freq, setVoiceFreq, writeCutoffX
.import pwLo, pwHi, valFrac, valLo, valHi, sweepLeft

.rodata

; The bit of SID_MODE_REG for each SID. They aren't in address order.
sidModeBits: .byte $02, $08, $01, $04

; The bit of SID_RESFILT for each voice
voiceBits:
    .byte $01, $02, $04
    .byte $01, $02, $04
    .byte $01, $02, $04
    .byte $01, $02, $04

.bss

mask: .res 1
cutoff: .res 2

.code

; Stores A in the shadow of the control register of voice voiceIdx and
; in the register. The IRQ handler changes the control register too (it
; closes the gate when a note ends), so a caller reads the shadow, changes
; it and calls this between sei and here: writeCtrl ends with plp.
.proc writeCtrl
    ldx voiceIdx
    sta ctrlShadow,x
    ldy voiceReg
    sta SID_BASE+SID_CTRL,y
    plp
    rts
.endproc

; Stores A in the shadow of SID_RESFILT of SID sidIdx and in the register
.proc writeResFilt
    ldx sidIdx
    sta resShadow,x
    ldy sidReg
    sta SID_BASE+SID_RESFILT,y
    rts
.endproc

; Stores A in the shadow of SID_MODEVOL of SID sidIdx and in the register
.proc writeModeVol
    ldx sidIdx
    sta modeShadow,x
    ldy sidReg
    sta SID_BASE+SID_MODEVOL,y
    rts
.endproc

; Procedure SetSidMode(sid : Byte; is8580 : Boolean);
.proc setSidMode
    jsr loadSid
    bcs DN
    lda #1
    jsr loadByteParam
    ldx sidIdx
    lda SID_MODE_REG
    ora sidModeBits,x       ; 8580
    ldy arg
    bne :+                  ; Branch if is8580
    eor sidModeBits,x       ; 6581
:   sta SID_MODE_REG
DN: rts
.endproc

; Procedure SetVolume(sid, volume : Byte);
.proc setVolume
    jsr loadSid
    bcs DN
    lda #1
    jsr loadByteParam
    and #$0f
    sta arg
    ldx sidIdx
    lda modeShadow,x
    and #$f0
    ora arg
    jmp writeModeVol
DN: rts
.endproc

; Procedure SetWaveform(voice : Byte; waveform : Word);
.proc setWaveform
    jsr loadVoice
    bcs DN
    lda #1
    jsr loadByteParam
    and #$f0
    sta arg
    php
    sei
    ldx voiceIdx
    lda ctrlShadow,x
    and #$0f
    ora arg
    jmp writeCtrl
DN: rts
.endproc

; Loads the Byte parameters numbered A and A+1 and returns the first in
; the high nibble of A and the second in the low nibble
.proc loadNibbles
    sta mask
    jsr loadByteParam
    asl a
    asl a
    asl a
    asl a
    sta cutoff
    ldx mask
    inx
    txa
    jsr loadByteParam
    and #$0f
    ora cutoff
    rts
.endproc

; Procedure SetEnvelope(voice, attack, decay, sustain, release : Byte);
.proc setEnvelope
    jsr loadVoice
    bcs DN
    lda #1
    jsr loadNibbles
    ldy voiceReg
    sta SID_BASE+SID_AD,y
    lda #3
    jsr loadNibbles
    ldy voiceReg
    sta SID_BASE+SID_SR,y
DN: rts
.endproc

; Procedure SetFrequency(voice : Byte; freq : Word);
; Ends a frequency sweep on the voice and starts its vibrato over.
.proc setFrequency
    jsr loadVoice
    bcs DN
    lda #1
    jsr rtLibLoadParam
    sta freq
    stx freq+1
    jmp setVoiceFreq
DN: rts
.endproc

; Procedure SetPulseWidth(voice : Byte; width : Word);
; A pulse sweep on the voice (PulseSweep) goes on from the new width.
.proc setPulseWidth
    jsr loadVoice
    bcs DN
    lda #1
    jsr rtLibLoadParam
    sta cutoff
    txa
    and #$0f                ; 12 bits
    sta cutoff+1
    php
    sei                     ; The IRQ changes the width too
    ldx voiceIdx
    ldy voiceReg
    lda cutoff
    sta pwLo,x
    sta SID_BASE+SID_PWLO,y
    lda cutoff+1
    sta pwHi,x
    sta SID_BASE+SID_PWHI,y
    plp
DN: rts
.endproc

; Procedure SetGate(voice : Byte; on : Boolean);
.proc setGate
    lda #CTRL_GATE
    jmp setCtrlBit
.endproc

; Procedure SetRingMod(voice : Byte; on : Boolean);
.proc setRingMod
    lda #CTRL_RING
    jmp setCtrlBit
.endproc

; Procedure SetSync(voice : Byte; on : Boolean);
.proc setSync
    lda #CTRL_SYNC
    ; Fall through to setCtrlBit
.endproc

; Sets (parameter 1 True) or clears the bits in A of the control register
; of the voice in parameter 0
.proc setCtrlBit
    sta mask
    jsr loadVoice
    bcs DN
    lda #1
    jsr loadByteParam
    php
    sei
    ldx voiceIdx
    lda ctrlShadow,x
    ora mask
    ldy arg
    bne :+                  ; Branch if on
    eor mask
:   jmp writeCtrl
DN: rts
.endproc

; Procedure SetFilter(sid : Byte; cutoff : Word; resonance : Byte;
;     mode : Word);
; Ends a filter sweep on the SID. The cutoff is 11 bits.
.proc setFilter
    jsr loadSid
    bcs DN
    lda #1
    jsr rtLibLoadParam
    sta cutoff
    txa
    and #>MAX_CUTOFF
    sta cutoff+1
    php
    sei                     ; The IRQ changes the cutoff too
    lda sidIdx
    clc
    adc #SWEEP_SID
    tax
    lda #0
    sta sweepLeft,x
    sta valFrac,x
    lda cutoff
    sta valLo,x
    lda cutoff+1
    sta valHi,x
    jsr writeCutoffX
    plp

    lda #2                  ; Resonance
    jsr loadByteParam
    asl a
    asl a
    asl a
    asl a
    sta arg
    ldx sidIdx
    lda resShadow,x
    and #$0f
    ora arg
    jsr writeResFilt

    lda #3                  ; Mode
    jsr loadByteParam
    and #$70
    sta arg
    ldx sidIdx
    lda modeShadow,x
    and #$8f
    ora arg
    jmp writeModeVol
DN: rts
.endproc

; Procedure FilterVoice(voice : Byte; on : Boolean);
.proc filterVoice
    jsr loadVoice
    bcs DN
    lda #1
    jsr loadByteParam
    ldx voiceIdx
    lda voiceBits,x
    sta mask
    ldx sidIdx
    lda resShadow,x
    ora mask
    ldy arg
    bne :+                  ; Branch if on
    eor mask
:   jmp writeResFilt
DN: rts
.endproc

; Function GetOsc3(sid : Byte) : Byte;
.proc getOsc3
    lda #SID_OSC3
    jmp readSidReg
.endproc

; Function GetEnv3(sid : Byte) : Byte;
.proc getEnv3
    lda #SID_ENV3
    ; Fall through to readSidReg
.endproc

; Returns the register at offset A of the SID in parameter 0, or 0 for a
; bad SID number
.proc readSidReg
    sta mask
    jsr loadSid
    lda #0
    bcs RT                  ; Branch if a bad SID number
    lda sidReg
    clc
    adc mask
    tay
    lda SID_BASE,y
RT: ldx #0
    stx sreg
    stx sreg+1
    jmp rtLibReturnValue
.endproc
