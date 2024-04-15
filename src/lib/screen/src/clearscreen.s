;
; clearscreen.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; ClearScreen library function

.include "cbm_kernal.inc"

.export clearScreen

; This routine clears the screen

.proc clearScreen
    lda #$93
    jmp CHROUT
.endproc
