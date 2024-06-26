;
; writebool.s
; Ken Schenke (kenschenke@gmail.com)
;
; Writes a boolean to the output
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;

.include "runtime.inc"
.include "cbm_kernal.inc"

.export writeBool

.import leftpad, writeByte

.data

TRUE:  .asciiz "true"
FALSE: .asciiz "false"

.code

buffer: .res 1

; Write boolean TRUE or FALSE to output.
; Boolean value in .A
; Field width in .X
.proc writeBool
    ldy #' '
    sty buffer
    stx tmp1            ; field width in tmp1
    ldx #5              ; start with value width of 5
    cmp #0              ; is boolean value false?
    beq L1              ; if so, skip the next instruction
    dex                 ; value is true, so value width is 4
L1:
    pha                 ; save boolean on the CPU stack
    lda tmp1            ; load field width into A
    jsr leftpad         ; left pad
    pla                 ; pop boolean value off CPU stack
    bne L2              ; if value is true, skip ahead
    ldx #0
:   lda FALSE,x
    beq L3
    jsr writeByte
    inx
    bne :-
L2:
    ldx #0
:   lda TRUE,x
    beq L3
    jsr writeByte
    inx
    bne :-
L3:
    rts
.endproc
