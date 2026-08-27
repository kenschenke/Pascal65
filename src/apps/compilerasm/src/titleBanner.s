;
; titleBanner.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Show compiler title lines

.include "cbm_kernal.inc"

.export showTitleBanner

.data

strTitle1: .asciiz "Pascal65 v0.35-beta"
strTitle2: .asciiz "Copyright 2024-2026 by Ken Schenke"
strTitle3: .asciiz "See license.txt for license information"

.code

.proc showTitleBanner
    lda #13
    jsr CHROUT

    lda #<strTitle1
    sta titleAddr+1
    lda #>strTitle1
    sta titleAddr+2
    jsr showTitleLine

    lda #<strTitle2
    sta titleAddr+1
    lda #>strTitle2
    sta titleAddr+2
    jsr showTitleLine

    lda #<strTitle3
    sta titleAddr+1
    lda #>strTitle3
    sta titleAddr+2
    jsr showTitleLine

    lda #13
    jsr CHROUT

    rts
.endproc

showTitleLine:
    ldx #0
titleAddr:
    lda strTitle1,x
    beq titleDone
    jsr CHROUT
    inx
    bne titleAddr
titleDone:
    lda #13
    jsr CHROUT
    rts
