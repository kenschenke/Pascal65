;
; uint16comp.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024-2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "zeropage.inc"

.export ltUint16

; Compare if intOp1 is less than intOp2
; .A contains 1 if intOp1 < intOp2, 0 otherwise.
.proc ltUint16
    ; Compare the high bytes first
    lda intOp1 + 1
    cmp intOp2 + 1
    bcc L2
    bne L1

    ; Compare the lower bytes
    lda intOp1
    cmp intOp2
    bcc L2

L1:
    lda #0
    rts

L2:
    lda #1
    rts
.endproc
