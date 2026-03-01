;
; icodeOper.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "icode.inc"
.include "4510macros.inc"

.export operand1, operand2, operand3

.export icodeOper1Bool, icodeOper1Int, icodeOper1Long, icodeOper1Char
.export icodeOper1Short, icodeOper1Word, icodeOper1Real, icodeOper1Label
.export icodeOper1String, icodeOper2Label

.export icodeOper2Short

.export icodeOper3Short

.import icodeLabel

.bss

operand1: .res 5
operand2: .res 5
operand3: .res 5

.code

.proc icodeOper1Bool
    sta operand1+1

    lda #IC_BOO
    sta operand1
    rts
.endproc

.proc icodeOper1Char
    sta operand1+1

    lda #IC_CHR
    sta operand1
    rts
.endproc

.proc icodeOper1Int
    sta operand1+1
    stx operand1+2

    lda #IC_IWS
    sta operand1
    rts
.endproc

.proc icodeOper1Label
    lda #IC_LBL
    sta operand1

    lda #<icodeLabel
    sta operand1+1
    lda #>icodeLabel
    sta operand1+2
    rts
.endproc

.proc icodeOper2Label
    lda #IC_LBL
    sta operand2

    lda #<icodeLabel
    sta operand2+1
    lda #>icodeLabel
    sta operand2+2
    rts
.endproc

.proc icodeOper1Short
    sta operand1+1

    lda #IC_IBS
    sta operand1
    rts
.endproc

.proc icodeOper2Short
    sta operand2+1

    lda #IC_IBS
    sta operand2
    rts
.endproc

.proc icodeOper3Short
    sta operand3+1

    lda #IC_IBS
    sta operand3
    rts
.endproc

.proc icodeOper1Word
    sta operand1+1
    stx operand1+2

    lda #IC_IWU
    sta operand1
    rts
.endproc

.proc icodeOper1Long
    stq operand1+1

    lda #IC_ILS
    sta operand1
    rts
.endproc

.proc icodeOper1Real
    stq operand1+1
    lda #IC_FLT
    sta operand1
    rts
.endproc

.proc icodeOper1String
    stq operand1+1
    lda #IC_STR
    sta operand1
    rts
.endproc
