;
; initresolver.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Routine to load the resolver from disk

.include "cbm_kernal.inc"
.include "c64.inc"

.data

fnResolver: .byte "resolver,p,r"
fnResolver2:

.code

.export initResolver

.import loadfile

.proc initResolver
    ; Call SETNAM
    ldx #<fnResolver
    ldy #>fnResolver
    lda #fnResolver2-fnResolver
    jsr loadfile

    rts
.endproc
