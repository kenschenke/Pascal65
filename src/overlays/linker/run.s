;
; run.s
; Ken Schenke (kenschenke@gmail.com)
;
; Code to chain PRGs
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;

.include "cbm_kernal.inc"
.include "c64.inc"

.export _runPrg
.importzp ptr1, ptr2, tmp1

; void runPrg()
.proc _runPrg
    lda #$93
    jsr CHROUT      ; Clear the screen

L2:
    lda #<L4        ; Address of bootstrap code in ptr1
    sta ptr1
    lda #>L4
    sta ptr1 + 1
    lda #$d0        ; Destination address in ptr2
    sta ptr2
.ifdef __MEGA65__
    lda #$bf
.else
    lda #$cf
.endif
    sta ptr2 + 1
    ldy #L5-L4-1    ; Copy bootstrap code to safe spot in memory
L3:
    lda (ptr1),y
    sta (ptr2),y
    dey
    bpl L3
.ifdef __MEGA65__
    jmp $bfd0       ; Execute the bootstrap code to load the PRG
.else
    jmp $cfd0
.endif

L4:
    lda #0
    ldx DEVNUM
    ldy #$ff
    jsr SETLFS

    lda #5
    ldx #$ec
.ifdef __MEGA65__
    ldy #$bf
.else
    ldy #$cf
.endif
    jsr SETNAM

    lda #0
    tax
    tay
    jsr LOAD
.ifdef __MEGA65__
    jmp $2011
.else
    jmp $80d
.endif
FN: .asciiz "zzprg"
L5:
.endproc
