;
; paramListCreate.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; paramListCreate routine

.include "ast.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export paramListCreate

.import nameCreate, heapAlloc, rtPushQ, rtPopQ

; This routine creates a param_list structure
;
; Inputs - pointer to name in A/X (bank 0)
.proc paramListCreate
    pha
    phx

    ; Allocate the structure
    lda #.sizeof(param_list)
    ldx #0
    jsr heapAlloc
    stq ptr1

    ; Zero out the param_list structure
    lda #0
    ldz #.sizeof(param_list)-1
:   nop
    sta (ptr1),z
    dez
    bpl :-

    ; Set up the name
    ldq ptr1
    jsr rtPushQ
    plx
    pla
    jsr nameCreate
    stq ptr2
    jsr rtPopQ
    stq ptr1
    ldz #param_list::name+3
    ldx #3
:   lda ptr2,x
    nop
    sta (ptr1),z
    dez
    dex
    bpl :-

    ldq ptr1
    rts
.endproc
