;
; floatsub.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Routine to subtract one floating point number from another.
;
; Based on floating point routines published in the book
; 6502 Software Gourmet Guide & Cookbook
; by Robert Findley

.include "float.inc"

.export FPSUB

.import COMPLM, FPADD

; This routine subtracts FPOP from FPACC and leaves the result in FPACC.
; FPOP is also modified.

.proc FPSUB
    ldx #FOPLSW         ; Set pointer to FPOP least-significant byte
    ldy #3              ; Set precision counter
    jsr COMPLM          ; Complement FPACC
    jmp FPADD           ; Subtract by adding negative
.endproc
