;
; filewrite.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; fileWrite routine

.include "editor.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.import isQZero

.export fileWrite

; This routine writes the contents of the currentFile.
; The caller OPENs the file and sets the file number as the
; output channel. The caller is responsible for CLOSEing the
; file when this routine returns.
.proc fileWrite
    ldz #EDITFILE::firstLine
    neg
    neg
    nop
    lda (currentFile),z
    stq ptr1                ; Use ptr1 for the current line
L1: jsr isQZero
    beq L4
    ldz #EDITLINE::buffer
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2                ; Line buffer in ptr2
    ldz #EDITLINE::length
    nop
    lda (ptr1),z
    beq L3
    ldz #0
    sta tmp1                ; tmp1 is line length
L2: nop
    lda (ptr2),z
    jsr CHROUT
    inz
    dec tmp1
    bne L2
L3: ; Write a CR
    lda #13
    jsr CHROUT
    ; Move to the next line in the file
    ldz #EDITLINE::next
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    bra L1
L4: rts
.endproc
