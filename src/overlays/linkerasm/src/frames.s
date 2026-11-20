;
; frames.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; The level 1 frames
;
; The program's global stack frame holds the program's own level 1 slots,
; then each unit's and library's, in the order the startup pushes them.
; Code reaches a unit's slot by its offset in the unit's frame, with a
; LINKADDR_FRAME relocation against the import "name.frame" (linker.inc).
; readFrames defines each one, once the modules are read (deferSymbol), as
; the frame's first slot: the program's global slots, then the slot
; counts of the frames before it.

.include "asmlib.inc"
.include "linker.inc"
.include "error.inc"
.include "4510macros.inc"

.export readFrames, setGlobalSlots, checkSlots

.import readByte, readName, symName, deferSymbol

.data

strFrame: .asciiz ".frame"

.bss

base: .res 2                ; the next frame's first slot
left: .res 1
slots: .res 2

.code

; This routine sets the program's own level 1 slots, from A/X, where the
; first frame starts
.proc setGlobalSlots
    sta base
    stx base+1
    rts
.endproc

; This routine reads the object file's frames and defines "name.frame" for
; each. The carry is set if the file is bad.
.proc readFrames
    jsr readByte
    sta left
L1: lda left
    bne :+
    clc
    rts
:   dec left

    ; The name, then ".frame"
    jsr readName                ; Into symName, its length in X
    bcs BD
    cpx #OBJ_NAME_MAX - .strlen(".frame") + 1
    bcs BD
    ldy #0
:   lda strFrame,y
    sta symName,x
    beq :+
    inx
    iny
    bra :-
:   lda base
    ldx base+1
    ldy #$ff                    ; an address, defined with the rest
    jsr deferSymbol

    ; The next frame starts after this one's slots
    jsr readByte
    sta slots
    jsr readByte
    sta slots+1
    lda base
    clc
    adc slots
    sta base
    lda base+1
    adc slots+1
    sta base+1
    bra L1

BD: sec
    rts
.endproc

; This routine reports errTooManyVariables if the frames end past the
; 256 level 1 slots a variable operand's one-byte offset reaches, and
; returns the carry set. The resolver reports it at the variable for the
; modules it numbers, but a unit loaded from its TPU has only its
; interface's variables there (tpuload.s), so the frames' sum is checked
; here.
.proc checkSlots
    lda base+1
    beq OK                      ; under 256
    cmp #1
    bne ER
    lda base
    beq OK                      ; exactly 256
ER: lda #errTooManyVariables
    ldx #0
    ldy #0
    jsr compilerError
    sec
    rts
OK: clc
    rts
.endproc
