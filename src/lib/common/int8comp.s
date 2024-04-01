;
; int8comp.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Compare 8-bit integers
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

.export eqInt8, leInt8, ltInt8, geInt8, gtInt8

; Compare intOp1 and intOp2 for equality.
; .A contains 1 if equal, 0 otherwise
.proc eqInt8
    lda intOp1
    cmp intOp2
    bne :+
    lda #1
    rts
:   lda #0
    rts
.endproc

; Compare if intOp1 less than or equal to intOp2.
; .A contains 1 if intOp1 <= intOp2, 0 otherwise.
.proc leInt8
    jsr eqInt8
    bne :+
    jmp ltInt8
:   lda #1
    rts
.endproc

; Compare if intOp1 is less than intOp2
; .A contains 1 if intOp1 < intOp2, 0 otherwise.
.proc ltInt8
    lda intOp1
    cmp intOp2
    bvc L1
    eor #$80
L1:
    bpl L2
    lda #1
    rts
L2:
    lda #0
    rts
.endproc

; Compare if intOp1 is greather than intOp2
; .A contains 1 if intOp1 > intOp2, 0 otherwise.
.proc gtInt8
    jsr eqInt8
    bne :+
    jmp geInt8
:   lda #0
    rts
.endproc

; Compare if intOp1 is greater than or equal to intOp2.
; .A contains 1 if intOp1 >= intOp2, 0 otherwise.
.proc geInt8
    lda intOp1
    cmp intOp2
    bvc L1
    eor #$80
L1:
    bpl L2
    lda #0
    rts
L2:
    lda #1
    rts
.endproc

