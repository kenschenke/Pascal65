;
; covsave.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Coverage build support for resolvertest (make coverage, see the Makefile).
;
; The coverage map is COVSIZE bytes at COVMAP, above the program and below
; the overlays. Both are given with -D. covInit fills it with $80 (a probe
; shifts its byte right). covSave writes it to the disk as "resolver.cov".
; The resolver overlay is loaded again for every test, but the map is outside
; it, so it collects the probes of every test.

.include "cbm_kernal.inc"
.include "c64.inc"
.include "zeropage.inc"

.export covInit, covSave

; The program and its BSS must end below the map
.import __BSS_RUN__, __BSS_SIZE__
.assert __BSS_RUN__ + __BSS_SIZE__ <= COVMAP, error, "program overlaps COVMAP"
.assert COVMAP + COVSIZE <= $4000, error, "COVMAP overlaps the overlay"

.data

fname: .byte "resolver.cov"
fnameEnd:

.code

.proc covInit
    lda #$80
    ldx #0
L1:
.repeat ::COVSIZE / 256, i
    sta ::COVMAP + i * 256,x
.endrep
    inx
    bne L1
    rts
.endproc

.proc covSave
    lda #fnameEnd-fname
    ldx #<fname
    ldy #>fname
    jsr SETNAM
    lda #1
    ldx DEVNUM
    ldy #0
    jsr SETLFS
    lda #<COVMAP
    sta ptr1
    lda #>COVMAP
    sta ptr1+1
    lda #ptr1
    ldx #<(COVMAP + COVSIZE)
    ldy #>(COVMAP + COVSIZE)
    jmp SAVE
.endproc
