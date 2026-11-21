;
; handoff.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; The work device from the chain loader

.include "asm.inc"
.include "asmlib.inc"

.export takeHandoff, handedOff

.bss

; Non-zero if the chain loader handed over the work device: the editor
; was loaded by a program run from the IDE, not at a cold start.
handedOff: .res 1

.code

; A program run from the IDE chains back to pascal65 on the system disk,
; and its chain loader writes the magic and the work device to
; CHAIN_HANDOFF (asm.inc, prgChain.s in codegenasm). initLib has set both
; devices from DEVNUM: the system device. With the magic there, this sets
; workDevice from the hand-off and clears the magic, so a later cold start
; doesn't take it.
.proc takeHandoff
    lda #0
    sta handedOff
    lda CHAIN_HANDOFF
    cmp #CHAIN_MAGIC1
    bne DN
    lda CHAIN_HANDOFF+1
    cmp #CHAIN_MAGIC2
    bne DN
    lda CHAIN_HANDOFF+2
    sta workDevice
    lda #0
    sta CHAIN_HANDOFF
    sta CHAIN_HANDOFF+1
    inc handedOff
DN: rts
.endproc
