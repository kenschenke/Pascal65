;
; loadfile.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; loadfile routine

.include "cbm_kernal.inc"
.include "c64.inc"

.export loadfile

; This routine loads a file using the KERNAL's LOAD routine.
; On input, X contains low-byte of filename
; Y contains high-byte of filename
; A contains length of filename
.proc loadfile
    ; Call SETNAM
    jsr SETNAM

    ; Call SETLFS
    ldx DEVNUM
    lda #1
    tay
    iny
    jsr SETLFS

    ; Call LOAD
    lda #0
    jsr LOAD

    rts
.endproc
