;
; initlib.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Routine to load the ASM.LIB from disk

.include "cbm_kernal.inc"
.include "c64.inc"
.include "asmlib.inc"

.data

fnLib: .byte "asm.lib,p,r"
fnLib2:

.code

.export initLib

.import loadfile

.proc initLib
    ; The device the program was loaded from. loadfile reads it from
    ; asmlib, so it goes there before the load and again after, since
    ; the load overwrites it.
    lda DEVNUM
    pha
    sta sysDevice
    ldx #<fnLib
    ldy #>fnLib
    lda #fnLib2-fnLib
    jsr loadfile
    pla
    sta sysDevice
    sta workDevice
.ifdef WORKUNIT
    ; This set has a work disk (see the Makefile)
    lda #WORKUNIT
    sta workDevice
.endif

    rts
.endproc
