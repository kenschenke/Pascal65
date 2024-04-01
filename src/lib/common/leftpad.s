;
; leftpad.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Left padding for console output
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "cbm_kernal.inc"

.ifdef RUNTIME
.include "runtime.inc"
.else
.importzp tmp1
.endif

.export leftpad

; Left pad a field with spaces.
; Field width in .A
; Value width in .X
; tmp1 is clobbered
.proc leftpad
    cmp #0
    beq Done
    stx tmp1
    cmp tmp1
    bmi Done
    sec
    sbc tmp1
    tay
    lda #' '
Loop:
    dey
    bmi Done
    jsr CHROUT
    clc
    bcc Loop

Done:
    rts
.endproc
