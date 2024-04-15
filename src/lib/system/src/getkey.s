;
; getkey.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "cbm_kernal.inc"
.include "runtime.inc"

.export getkey, getkeynowait

getkey:
    lda #1
    jsr rtGetKey
    jmp DN

getkeynowait:
    lda #0
    jsr rtGetKey

DN:
    ldx #0
    stx sreg
    stx sreg + 1
    jmp rtLibReturnValue
