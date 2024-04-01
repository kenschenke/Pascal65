;
; uint16comp.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Unsigned 16-bit integer comparison
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.ifdef RUNTIME
.include "runtime.inc"
.else
.import intOp1, intOp2
.endif


.import eqInt16

.export geUint16, gtUint16, leUint16, ltUint16

; Compare if intOp1 is greater than or equal to intOp2
; .A contains 1 if intOp1 >= intOp2, 0 otherwise
.proc geUint16
    ; Compare the high bytes first
    lda intOp1 + 1
    cmp intOp2 + 1
    bcc L1
    bne L2
    
    ; Compare the low bytes
    lda intOp1
    cmp intOp2
    bcs L2

L1:
    lda #0
    rts

L2:
    lda #1
    rts
.endproc

; Compare if intOp1 is greater than intOp2
; .A contains 1 if intOp1 > intOp2, 0 otherwise
.proc gtUint16
    jsr eqInt16
    bne L1
    jmp geUint16

L1:
    lda #0
    rts
.endproc

; Compare if intOp1 is less than or equal to intOp2
; .A contains 1 if intOp1 <= intOp2, 0 otherwise.
.proc leUint16
    jsr eqInt16
    bne L1
    jmp ltUint16

L1:
    lda #1
    rts
.endproc

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
