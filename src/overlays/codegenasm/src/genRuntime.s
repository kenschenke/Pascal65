;
; genRuntime.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; genRuntime routine

.include "c64.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"

RUNTIME_BSS_LENGTH = 200

.export genRuntime

.import incCodeOffset

.data

runtimeFn: .asciiz "runtime,p,r"
runtimeFn2:

.code

.proc genRuntime
    ; Open the runtime file
    ; Call SETLFS
    ldx DEVNUM
    lda #2
    tay
    iny
    jsr SETLFS
    ; Call SETNAM
    ldx #<runtimeFn
    ldy #>runtimeFn
    lda #runtimeFn2-runtimeFn
    jsr SETNAM
    ; Open the file and set input channel
    jsr OPEN
    ldx #2
    jsr CHKIN

    ; Discard the starting address
    jsr CHRIN
    jsr CHRIN

    ; Loop, reading the runtime file and writing it to the object code file
L1: ldx #2
    jsr CHKIN
    jsr CHRIN
    pha
    lda STATUS
    and #$40
    bne L2
    ldx #1
    jsr CHKOUT
    pla
    jsr CHROUT

    lda #1
    jsr incCodeOffset
    bra L1

L2: pla

    ; Write an extra 200 bytes for BSS
    ldx #1
    jsr CHKOUT
    lda #0
    ldx #RUNTIME_BSS_LENGTH
L3: jsr CHROUT
    dex
    bne L3

    lda #RUNTIME_BSS_LENGTH
    jsr incCodeOffset

    lda #2
    jsr CLOSE
    ldx #0
    jsr CHKIN
    ldx #1
    jsr CHKOUT
    rts
.endproc
