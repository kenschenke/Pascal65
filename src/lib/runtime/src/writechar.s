;
; writechar.s
; Ken Schenke (kenschenke@gmail.com)
;
; Writes a character to the output
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;

.include "cbm_kernal.inc"

.export writeChar

.import leftpad, writeByte

; Write character output.
; Character in .A
; Field width in .X
.proc writeChar
    pha
    txa
    ldx #1
    jsr leftpad
    pla
    jsr writeByte
    rts
.endproc
