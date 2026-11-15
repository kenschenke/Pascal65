;
; effects.s
; Ken Schenke (kenschenke@gmail.com)
;
; Sound library effects: frequency and filter sweeps, vibrato and pulse
; width sweeps, run by the raster IRQ each frame
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; A sweep moves a value in a straight line to a target, one step a frame.
; Sweeps 0-11 move a voice's base frequency and 12-15 (SWEEP_SID) a SID's
; filter cutoff. The value and step are 16.8 fixed point, so a slow sweep
; still moves, and the last frame sets the target exactly.
;
; Vibrato swings a voice's frequency above and below its base frequency
; in a triangle wave. Its offset is 16.8 fixed point too. It goes up for
; half a swing, then down and up a whole swing at a time, by the same
; step, so it never drifts. The step is worked out from the base
; frequency when the vibrato or a note starts:
;
;     step = base * depth / (2 * frames)     (in 1/256ths)
;
; which makes the peak base * depth / 1024.
;
; A pulse sweep adds its step to the voice's pulse width each frame and
; turns around at PW_MIN and PW_MAX.
;
; The IRQ writes the registers these change, so the main program changes
; their state between sei and plp, and calls writeFreqX and writeCutoffX
; only there.

.include "runtime.inc"
.include "sound.inc"

.export initEffects, stopEffectsX, stopFilterSweeps, runEffects
.export setVoiceFreq, writeFreqX, writeCutoffX
.export pwLo, pwHi, valFrac, valLo, valHi, sweepLeft
.export sweep, vibrato, pulseSweep, filterSweep
.export getFrequency, getPulseWidth, getCutoff

.import loadVoice, loadSid, loadByteParam, voiceRegs
.import voiceIdx, sidIdx, arg
.import installIrq, irqWork
.import freq, returnAX

.bss

startbss:
; Sweeps, NUM_SWEEPS each
valFrac: .res NUM_SWEEPS    ; Base frequency or cutoff (16.8)
valLo: .res NUM_SWEEPS
valHi: .res NUM_SWEEPS
stepFrac: .res NUM_SWEEPS   ; Step a frame (16.8, unsigned)
stepLo: .res NUM_SWEEPS
stepHi: .res NUM_SWEEPS
tgtLo: .res NUM_SWEEPS      ; Target
tgtHi: .res NUM_SWEEPS
sweepLeft: .res NUM_SWEEPS  ; Frames left, 0 if not sweeping
sweepDown: .res NUM_SWEEPS  ; Nonzero if the value falls

; Vibrato, NUM_VOICES each
vibFrames: .res NUM_VOICES  ; Frames a swing, 0 if off
vibDepth: .res NUM_VOICES
vibCount: .res NUM_VOICES   ; Frames left in this swing
vibDown: .res NUM_VOICES    ; Nonzero if falling
vibStepF: .res NUM_VOICES   ; Step a frame (16.8, unsigned)
vibStepL: .res NUM_VOICES
vibStepH: .res NUM_VOICES
vibOffF: .res NUM_VOICES    ; Offset from the base (16.8, signed)
vibOffL: .res NUM_VOICES
vibOffH: .res NUM_VOICES

outLo: .res NUM_VOICES      ; The frequency last written (GetFrequency)
outHi: .res NUM_VOICES

; Pulse width, NUM_VOICES each
pwLo: .res NUM_VOICES       ; The width (SetPulseWidth's shadow)
pwHi: .res NUM_VOICES
pStepLo: .res NUM_VOICES    ; Step a frame (signed), 0 if off
pStepHi: .res NUM_VOICES
endbss:

BSS_HALF = (endbss-startbss+1)/2
.assert BSS_HALF <= 256, error, "effects BSS is over 512 bytes"

; Only used between sei and plp, or by the IRQ
wtmp: .res 2

; Only used by the main program, outside the IRQ
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

.code

; Clears the effects' state. Two loops of half the size each cover it, one
; byte twice if the size is odd.
.proc initEffects
    ldx #BSS_HALF-1
    lda #0
:   sta startbss,x
    sta endbss-BSS_HALF,x
    dex
    cpx #$ff
    bne :-
    rts
.endproc

; Ends the effects on voice X (0-11) and puts its base frequency back in
; the register. Call it with interrupts disabled. Keeps X.
.proc stopEffectsX
    lda #0
    sta sweepLeft,x
    sta pStepLo,x
    sta pStepHi,x
    sta vibFrames,x
    jmp writeFreqX
.endproc

; Ends the four filter sweeps. The cutoffs stay where they are.
.proc stopFilterSweeps
    php
    sei
    ldx #NUM_SIDS-1
    lda #0
:   sta sweepLeft+SWEEP_SID,x
    dex
    bpl :-
    plp
    rts
.endproc

; Writes the frequency of voice X (0-11), its base plus its vibrato
; offset, to the register and to outLo/outHi. It stays in 0-$FFFF. Call
; it with interrupts disabled. Keeps X.
.proc writeFreqX
    lda vibFrames,x
    bne VB                  ; Branch if vibrato
    lda valLo,x
    sta outLo,x
    lda valHi,x
    sta outHi,x
    jmp WR
VB: clc
    lda valLo,x
    adc vibOffL,x
    sta outLo,x
    lda valHi,x
    adc vibOffH,x
    sta outHi,x
    lda vibOffH,x           ; Keeps the carry
    bmi NG                  ; Branch if the offset is negative
    bcc WR                  ; Branch if no overflow
    lda #$ff
    bne CL
NG: bcs WR                  ; Branch if no borrow
    lda #0
CL: sta outLo,x
    sta outHi,x
WR: ldy voiceRegs,x
    lda outLo,x
    sta SID_BASE+SID_FREQLO,y
    lda outHi,x
    sta SID_BASE+SID_FREQHI,y
    rts
.endproc

; Writes the cutoff of sweep X (SWEEP_SID to SWEEP_SID+3) to its SID's
; registers. Call it with interrupts disabled. Keeps X.
.proc writeCutoffX
    ldy voiceRegs,x
    lda valLo,x
    and #$07                ; Bits 0-2
    sta SID_BASE+SID_CUTLO,y
    lda valHi,x             ; Bits 3-10
    sta wtmp
    lda valLo,x
    lsr wtmp
    ror a
    lsr wtmp
    ror a
    lsr wtmp
    ror a
    sta SID_BASE+SID_CUTHI,y
    rts
.endproc

; Sets the base frequency of voice voiceIdx to freq, ends its sweep,
; starts its vibrato over and writes the register
.proc setVoiceFreq
    ldx voiceIdx
    lda vibFrames,x         ; Only the main program changes it
    beq :+                  ; Branch if no vibrato
    lda freq
    sta mBase
    lda freq+1
    sta mBase+1
    lda vibDepth,x
    sta mulBy
    lda vibFrames,x
    sta divBy
    jsr calcVibStep
:   php
    sei
    ldx voiceIdx
    lda freq
    sta valLo,x
    lda freq+1
    sta valHi,x
    lda #0
    sta valFrac,x
    sta sweepLeft,x
    jsr resetVibX
    jsr writeFreqX
    plp
    rts
.endproc

; Starts the vibrato of voice X over with newStep. Call it with
; interrupts disabled. Keeps X.
.proc resetVibX
    lda newStep
    sta vibStepF,x
    lda newStep+1
    sta vibStepL,x
    lda newStep+2
    sta vibStepH,x
    lda #0
    sta vibOffF,x
    sta vibOffL,x
    sta vibOffH,x
    sta vibDown,x
    lda vibFrames,x         ; The first swing is half of one
    clc
    adc #1
    ror a                   ; (frames + 1) / 2, with the carry as bit 8
    sta vibCount,x
    rts
.endproc

; newStep = mBase * mulBy / divBy / 2 (see the top of the file). divBy
; must not be 0. Keeps X.
.proc calcVibStep
    txa
    pha
    lda #0
    sta prod
    sta prod+1
    sta prod+2
    ldx #8
L1: asl prod                ; Multiply, from mulBy's high bit
    rol prod+1
    rol prod+2
    asl mulBy
    bcc :+
    clc
    lda prod
    adc mBase
    sta prod
    lda prod+1
    adc mBase+1
    sta prod+1
    lda prod+2
    adc #0
    sta prod+2
:   dex
    bne L1
    jsr div24
    lsr prod+2
    ror prod+1
    ror prod
    lda prod
    sta newStep
    lda prod+1
    sta newStep+1
    lda prod+2
    sta newStep+2
    pla
    tax
    rts
.endproc

; Divides prod (24 bits) by divBy, which isn't 0. The quotient is left in
; prod and the remainder in rem.
.proc div24
    lda #0
    sta rem
    ldx #24
L1: asl prod
    rol prod+1
    rol prod+2
    rol rem
    bcs SB                  ; Branch if the remainder is over 255
    lda rem
    cmp divBy
    bcc NX                  ; Branch if less than the divisor
SB: lda rem
    sbc divBy               ; The carry is set
    sta rem
    inc prod                ; Bit 0 is 0 after the asl
NX: dex
    bne L1
    rts
.endproc

; Starts sweep sweepIdx from sFrom to sTo over sFrames frames. 0 frames
; sets sTo at once.
.proc startSweep
    lda sFrames
    bne :+
    lda sTo                 ; 0 frames: start at the target
    sta sFrom
    lda sTo+1
    sta sFrom+1
:   lda #0                  ; prod = |sTo - sFrom| * 256
    sta prod
    sta sDown
    sec
    lda sTo
    sbc sFrom
    sta prod+1
    lda sTo+1
    sbc sFrom+1
    sta prod+2
    bcs :+                  ; Branch if rising
    inc sDown
    sec
    lda #0
    sbc prod+1
    sta prod+1
    lda #0
    sbc prod+2
    sta prod+2
:   lda sFrames
    beq :+
    sta divBy
    jsr div24               ; The step
:   php
    sei
    ldx sweepIdx
    lda #0
    sta valFrac,x
    lda sFrom
    sta valLo,x
    lda sFrom+1
    sta valHi,x
    lda sTo
    sta tgtLo,x
    lda sTo+1
    sta tgtHi,x
    lda prod
    sta stepFrac,x
    lda prod+1
    sta stepLo,x
    lda prod+2
    sta stepHi,x
    lda sDown
    sta sweepDown,x
    lda sFrames
    sta sweepLeft,x
    beq :+                  ; Branch if done
    sta irqWork
:   cpx #SWEEP_SID
    bcs CU                  ; Branch if a filter sweep
    jsr writeFreqX
    plp
    rts
CU: jsr writeCutoffX
    plp
    rts
.endproc

; Procedure Sweep(voice : Byte; fromFreq, toFreq : Word; frames : Byte);
.proc sweep
    jsr loadVoice
    bcs DN
    lda voiceIdx
    sta sweepIdx
    lda #1
    jsr rtLibLoadParam
    sta sFrom
    stx sFrom+1
    lda #2
    jsr rtLibLoadParam
    sta sTo
    stx sTo+1
    lda #3
    jsr loadByteParam
    sta sFrames
    jsr installIrq
    jmp startSweep
DN: rts
.endproc

; Procedure FilterSweep(sid : Byte; toCutoff : Word; frames : Byte);
; The sweep starts from the SID's cutoff. The target is 11 bits.
.proc filterSweep
    jsr loadSid
    bcs DN
    lda sidIdx
    clc
    adc #SWEEP_SID
    sta sweepIdx
    lda #1
    jsr rtLibLoadParam
    sta sTo
    txa
    and #>MAX_CUTOFF
    sta sTo+1
    lda #2
    jsr loadByteParam
    sta sFrames
    ldx sweepIdx
    php
    sei                     ; The IRQ may be sweeping it
    lda valLo,x
    sta sFrom
    lda valHi,x
    sta sFrom+1
    plp
    jsr installIrq
    jmp startSweep
DN: rts
.endproc

; Procedure Vibrato(voice, depth, frames : Byte);
; A depth or frames of 0 turns it off.
.proc vibrato
    jsr loadVoice
    bcs DN
    lda #1
    jsr loadByteParam
    sta mulBy
    sta vDepth              ; calcVibStep shifts mulBy
    lda #2
    jsr loadByteParam
    sta divBy
    beq OF                  ; Branch if 0 frames
    lda mulBy
    beq OF                  ; Branch if no depth
    jsr installIrq
    ldx voiceIdx
    php
    sei                     ; The IRQ may be sweeping the base
    lda valLo,x
    sta mBase
    lda valHi,x
    sta mBase+1
    plp
    jsr calcVibStep
    php
    sei
    lda vDepth
    sta vibDepth,x
    lda arg                 ; The frames
    sta vibFrames,x
    jsr resetVibX
    jsr writeFreqX
    lda #1
    sta irqWork
    plp
DN: rts
OF: php
    sei
    ldx voiceIdx
    lda #0
    sta vibFrames,x
    jsr writeFreqX          ; Back to the base frequency
    plp
    rts
.endproc

; Procedure PulseSweep(voice : Byte; stepSize : Integer);
; 0 turns it off.
.proc pulseSweep
    jsr loadVoice
    bcs DN
    jsr installIrq
    lda #1
    jsr rtLibLoadParam
    ldy voiceIdx
    php
    sei
    sta pStepLo,y
    txa
    sta pStepHi,y
    lda #1
    sta irqWork
    plp
DN: rts
.endproc

; Function GetFrequency(voice : Byte) : Word;
; The frequency last written to the voice's register
.proc getFrequency
    jsr loadVoice
    bcs BD
    ldy voiceIdx
    php
    sei
    lda outLo,y
    ldx outHi,y
    plp
    jmp returnAX
BD: lda #0
    tax
    jmp returnAX
.endproc

; Function GetPulseWidth(voice : Byte) : Word;
.proc getPulseWidth
    jsr loadVoice
    bcs BD
    ldy voiceIdx
    php
    sei
    lda pwLo,y
    ldx pwHi,y
    plp
    jmp returnAX
BD: lda #0
    tax
    jmp returnAX
.endproc

; Function GetCutoff(sid : Byte) : Word;
.proc getCutoff
    jsr loadSid
    bcs BD
    lda sidIdx
    clc
    adc #SWEEP_SID
    tay
    php
    sei
    lda valLo,y
    ldx valHi,y
    plp
    jmp returnAX
BD: lda #0
    tax
    jmp returnAX
.endproc

; Runs the effects for a frame, from the IRQ handler. Adds 1 to irqWork
; for each effect still running.
.proc runEffects
    ldx #NUM_SWEEPS-1
L1: lda sweepLeft,x
    beq N1                  ; Branch if not sweeping
    jsr stepSweepX
    lda sweepLeft,x
    beq :+                  ; Branch if it just ended
    inc irqWork
:   cpx #SWEEP_SID
    bcs CU                  ; Branch if a filter sweep
    lda vibFrames,x
    bne N1                  ; Branch if the vibrato below writes it
    jsr writeFreqX
    jmp N1
CU: jsr writeCutoffX
N1: dex
    bpl L1

    ldx #NUM_VOICES-1
L2: lda vibFrames,x
    beq PW                  ; Branch if no vibrato
    inc irqWork
    jsr stepVibX
    jsr writeFreqX
PW: lda pStepLo,x
    ora pStepHi,x
    beq N2                  ; Branch if no pulse sweep
    inc irqWork
    jsr stepPulseX
N2: dex
    bpl L2
    rts
.endproc

; Moves sweep X one frame. The last frame sets the target. Keeps X.
.proc stepSweepX
    lda sweepDown,x
    bne DN                  ; Branch if falling
    clc
    lda valFrac,x
    adc stepFrac,x
    sta valFrac,x
    lda valLo,x
    adc stepLo,x
    sta valLo,x
    lda valHi,x
    adc stepHi,x
    sta valHi,x
    jmp CT
DN: sec
    lda valFrac,x
    sbc stepFrac,x
    sta valFrac,x
    lda valLo,x
    sbc stepLo,x
    sta valLo,x
    lda valHi,x
    sbc stepHi,x
    sta valHi,x
CT: dec sweepLeft,x
    bne RT                  ; Branch if frames are left
    lda #0
    sta valFrac,x
    lda tgtLo,x
    sta valLo,x
    lda tgtHi,x
    sta valHi,x
RT: rts
.endproc

; Moves the vibrato of voice X one frame. Keeps X.
.proc stepVibX
    lda vibDown,x
    bne DN                  ; Branch if falling
    clc
    lda vibOffF,x
    adc vibStepF,x
    sta vibOffF,x
    lda vibOffL,x
    adc vibStepL,x
    sta vibOffL,x
    lda vibOffH,x
    adc vibStepH,x
    sta vibOffH,x
    jmp CT
DN: sec
    lda vibOffF,x
    sbc vibStepF,x
    sta vibOffF,x
    lda vibOffL,x
    sbc vibStepL,x
    sta vibOffL,x
    lda vibOffH,x
    sbc vibStepH,x
    sta vibOffH,x
CT: dec vibCount,x
    bne RT                  ; Branch if the swing goes on
    lda vibFrames,x
    sta vibCount,x
    lda vibDown,x
    eor #1
    sta vibDown,x
RT: rts
.endproc

; Moves the pulse width of voice X one frame and writes it. It turns
; around at PW_MIN and PW_MAX. Keeps X.
.proc stepPulseX
    clc
    lda pwLo,x
    adc pStepLo,x
    sta wtmp
    lda pwHi,x
    adc pStepHi,x
    sta wtmp+1
    ldy pStepHi,x           ; Keeps the carry
    bmi NG                  ; Branch if falling
    ; Rising. The width is under 4096 and the step under 32768, so the
    ; sum can't carry.
    lda wtmp+1
    cmp #>PW_MAX
    bcc OK                  ; Branch if under PW_MAX
    bne TU                  ; Branch if over
    lda wtmp
    cmp #<PW_MAX
    bcc OK
    beq OK
TU: lda #<PW_MAX
    sta wtmp
    lda #>PW_MAX
    sta wtmp+1
    jmp RV
NG: bcc TD                  ; Branch if under 0
    lda wtmp+1
    cmp #>PW_MIN
    bcc TD                  ; Branch if under PW_MIN
    bne OK                  ; Branch if over
    lda wtmp
    cmp #<PW_MIN
    bcs OK
TD: lda #<PW_MIN
    sta wtmp
    lda #>PW_MIN
    sta wtmp+1
RV: sec                     ; Turn around
    lda #0
    sbc pStepLo,x
    sta pStepLo,x
    lda #0
    sbc pStepHi,x
    sta pStepHi,x
OK: ldy voiceRegs,x
    lda wtmp
    sta pwLo,x
    sta SID_BASE+SID_PWLO,y
    lda wtmp+1
    sta pwHi,x
    sta SID_BASE+SID_PWHI,y
    rts
.endproc
