;
; sound.inc
; Ken Schenke (kenschenke@gmail.com)
;
; Sound library definitions
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

NUM_VOICES = 12
NUM_SIDS = 4

; The four SIDs are at $D400, $D420, $D440 and $D460. SIDs 1 and 2 are
; panned right, 3 and 4 left.
SID_BASE = $d400
SID_SIZE = $20

; Voice registers, from the voice's offset
SID_FREQLO = $00
SID_FREQHI = $01
SID_PWLO = $02
SID_PWHI = $03
SID_CTRL = $04
SID_AD = $05
SID_SR = $06

; SID registers, from the SID's offset
SID_CUTLO = $15             ; Cutoff bits 0-2
SID_CUTHI = $16             ; Cutoff bits 3-10
SID_RESFILT = $17           ; Resonance (bits 4-7), filtered voices (0-2)
SID_MODEVOL = $18           ; Filter mode (bits 4-6), volume (bits 0-3)
MODE_3OFF = $80             ; SID_MODEVOL: voice 3 off (SetVoice3Off)
SID_OSC3 = $1b              ; Voice 3's oscillator (readable)
SID_ENV3 = $1c              ; Voice 3's envelope (readable)

; Control register bits
CTRL_GATE = $01
CTRL_SYNC = $02
CTRL_RING = $04

; Bits of voiceFlags (engine.s)
VF_PLAYING = $01            ; Playing a note or sequence (IsPlaying)
VF_SEQ = $02                ; Playing a sequence (sequence.s)
VF_DONE = $04               ; Just ended, for the done callback

; Sequence bytes (sequence.s and the Seq constants in sound.pas). 0-95
; is a note.
SEQ_REST = 96               ; Length: closes the gate and waits
SEQ_WAVE = 97               ; Waveform: SetWaveform
SEQ_ENVELOPE = 98           ; Attack/decay, sustain/release
SEQ_TEMPO = 99              ; Frames a tick
SEQ_PULSE = 100             ; Low, high: SetPulseWidth
SEQ_LOOP = 101              ; Back to the start
SEQ_END = 102               ; Ends the sequence. So does any byte over it.

NUM_NOTES = 96              ; C0 to B7

; Sweeps (effects.s). Sweeps 0-11 move a voice's frequency and 12-15 a
; SID's filter cutoff.
SWEEP_SID = NUM_VOICES
NUM_SWEEPS = NUM_VOICES + NUM_SIDS
MAX_CUTOFF = 2047           ; The cutoff is 11 bits

; PulseSweep turns around at these pulse widths
PW_MIN = 128
PW_MAX = 3968

; startNote keeps the gate closed for this many loops before opening it
; again, so the envelope sees it closed (see startNote)
GATE_DELAY = 64

; Bit 7 is 1 on an NTSC MEGA65, 0 on PAL. The SIDs' clock and the frame
; rate follow it.
VIC_PAL = $d06f

; Bits 0-3 pick 6581 (0) or 8580 (1) for each SID, in the order
; 3, 1, 4, 2 (see sidModeBits)
SID_MODE_REG = $d63c
