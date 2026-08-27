;
; dataInstruction.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; dataInstruction routine

.include "asmlib.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export dataInstruction

.import operand3, saveDataSegment, readIcodeByte

.bss

membuf: .res 4
buffer: .res 1

.code

; This routine processes the contents of a DAT instruction.
; It reads the contents into a memory buffer and passes the
; information on to saveDataSegment. That routine saves
; everything in another membuf that is used later when writing
; the actual data segment into the object file.
.proc dataInstruction
    jsr allocMemBuf
    stq membuf

    ; Loop reading data segment contents
L1: lda operand3+1
    ora operand3+2
    beq DN

    jsr readIcodeByte
    sta buffer

    ldq membuf
    stq ptr1
    lda #<buffer
    sta ptr2
    lda #>buffer
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #1
    ldx #0
    jsr writeToMemBuf

    lda operand3+1
    sec
    sbc #1
    sta operand3+1
    lda operand3+2
    sbc #0
    sta operand3+2
    bra L1

DN: ldq membuf
    jsr saveDataSegment

    rts
.endproc
