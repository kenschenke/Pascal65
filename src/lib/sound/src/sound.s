;
; sound.s
; Ken Schenke (kenschenke@gmail.com)
;
; Sound library jump table
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; The first two entries are init and cleanup, then one per routine in the
; order of sound.pas. A change here changes __JMPTBLSIZE__ in sound.cfg.

.import noteFreq, playNote, playFreq, isPlaying, stopVoice, stopAllVoices
.import frameRate
.import initSoundLibrary, cleanupSoundLibrary
.import setSidMode, setVolume, setWaveform, setEnvelope, setFrequency
.import setPulseWidth, setGate, setRingMod, setSync, setFilter
.import filterVoice, getOsc3, getEnv3

.segment "JMPTBL"

jmp initSoundLibrary
jmp cleanupSoundLibrary
jmp setSidMode
jmp setVolume
jmp setWaveform
jmp setEnvelope
jmp setFrequency
jmp setPulseWidth
jmp setGate
jmp setRingMod
jmp setSync
jmp setFilter
jmp filterVoice
jmp getOsc3
jmp getEnv3
jmp noteFreq
jmp playNote
jmp playFreq
jmp isPlaying
jmp stopVoice
jmp stopAllVoices
jmp frameRate
