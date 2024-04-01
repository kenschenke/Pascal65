;
; printz.s
; Ken Schenke (kenschenke@gmail.com)
;
; Output null-terminated string to console
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;

.include "cbm_kernal.inc"
.include "runtime.inc"

.export printz, printlnz

.import writeData, writeByte

.proc printz
    sta ptr1
    stx ptr1 + 1
    ldy #0
L1:
    lda (ptr1),y
    beq L2
    iny
    bne L1
L2:
    lda ptr1
    ldx ptr1 + 1
    jmp writeData
.endproc

.proc printlnz
    jsr printz
    lda #13
    jmp writeByte
.endproc
