;
; dumpDataSegment.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; dumpHex routine

.include "cbm_kernal.inc"

MAX_COUNT = 20

.export dumpDataSegment

.import readOperand, dumpChar, dumpHexByte

.bss

; Segment length
seglen: .res 2
count: .res 1

.code

.proc dumpDataSegment
    jsr readOperand         ; the label

    ; Read the operand data type
    jsr CHRIN
    ; Ignore it - it should be IC_IWU

    ; Read the segment length
    jsr CHRIN
    sta seglen
    jsr CHRIN
    sta seglen+1

    ; Start a new line
L1: lda #13
    jsr dumpChar

    ; Indent
    lda #' '
    jsr dumpChar
    lda #' '
    jsr dumpChar
    lda #' '
    jsr dumpChar

    ; Write no more than MAX_COUNT bytes per screen line
    lda #0
    sta count

L2: lda seglen
    ora seglen+1
    beq L3

    lda count
    cmp #MAX_COUNT
    beq L1

    jsr CHRIN
    jsr dumpHexByte
    lda #' '
    jsr dumpChar

    lda seglen
    sec
    sbc #1
    sta seglen
    lda seglen+1
    sbc #0
    sta seglen+1

    inc count
    bra L2

L3: rts
.endproc
