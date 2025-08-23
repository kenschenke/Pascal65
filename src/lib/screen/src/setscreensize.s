;
; setscreensize.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "runtime.inc"
.include "cbm_kernal.inc"

.export setScreenSize

; Only 80x25, 80x50, and 40x25 are supported.
; If anything other than the three supported are requested, the default
; of 80x25 is used.

.proc setScreenSize
    lda #'8'
    sta tmp1                ; Start with the default of 80x25
    lda #0
    jsr rtLibLoadParam
    cmp #80                 ; Set to 80 columns?
    beq L1                  ; Branch if A == 80
    cmp #40                 ; Set to 40 columns?
    bne L2                  ; Branch if A != 40
    lda #'4'
    sta tmp1
    bne L2
L1: lda #1
    jsr rtLibLoadParam
    cmp #50                 ; Set to 50 rows?
    bne L2                  ; Branch if A != 50
    lda #'5'
    sta tmp1
L2: lda #27
    jsr CHROUT
    lda tmp1
    jmp CHROUT
.endproc
