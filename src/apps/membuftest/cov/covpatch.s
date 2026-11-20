;
; covpatch.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Coverage build support for membuftest (see the Makefile).
;
; The coverage build links instrumented copies of the membuf routines, with
; the jump table's names given a cov_ prefix. covInstall points asmlib's jump
; table entries at the copies, so the tests run them without any changes,
; and fills the coverage map with $80 (a probe shifts its byte right).
; covSave writes the map to the disk as "membuf.cov".
;
; The map is COVSIZE bytes at COVMAP, above the program. Both are given
; with -D.
;
; The copies import routines that asmlib doesn't export. They are resolved
; to its jump table here.

.include "cbm_kernal.inc"
.include "c64.inc"
.include "asmlib.inc"
.include "zeropage.inc"

.export covInstall, covSave
.export heapAlloc, heapFree, isQZero, ltUint16, subInt16

.import cov_allocMemBuf, cov_freeMemBuf, cov_getMemBufPos
.import cov_readFromMemBuf, cov_setMemBufPos, cov_writeToMemBuf
.import cov_isMemBufAtEnd

; The program and its BSS must end below the map
.import __BSS_RUN__, __BSS_SIZE__
.assert __BSS_RUN__ + __BSS_SIZE__ <= COVMAP, error, "program overlaps COVMAP"
.assert COVMAP + COVSIZE <= ASMBASE, error, "COVMAP overlaps asmlib"

; Replaces the address of the JMP at entry with target
.macro PATCH entry, target
    lda #<target
    sta entry+1
    lda #>target
    sta entry+2
.endmacro

.data

fname: .byte "membuf.cov"
fnameEnd:

.code

.proc covInstall
    PATCH allocMemBuf, cov_allocMemBuf
    PATCH freeMemBuf, cov_freeMemBuf
    PATCH getMemBufPos, cov_getMemBufPos
    PATCH readFromMemBuf, cov_readFromMemBuf
    PATCH setMemBufPos, cov_setMemBufPos
    PATCH writeToMemBuf, cov_writeToMemBuf
    PATCH isMemBufAtEnd, cov_isMemBufAtEnd

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
    ldx workDevice
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
