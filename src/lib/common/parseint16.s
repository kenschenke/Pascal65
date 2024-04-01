;
; parseint16.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Convert a PETSCII string into a 16-bit integer
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.import intOp1, readInt16
.importzp ptr1, intPtr

.export _parseInt16

; This routine parses a 16-bit integer from a string.
; The caller passes a pointer to a NULL-terminated string
; and the integer is returned in A/X.
; int parseInt16(char *buffer)
.proc _parseInt16
    sta ptr1
    stx ptr1 + 1

    ldy #0
L1:
    lda (ptr1),y
    sta (intPtr),y
    beq L2
    iny
    jmp L1
L2:
    jsr readInt16
    lda intOp1
    ldx intOp1 + 1
    rts
.endproc
