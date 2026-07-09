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

.import heapAlloc, rtPushQ, rtPopQ

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
    pla
    sta ptr2+1
    pla
    sta ptr2
    ldz #param_list::name
    ldy #0
:   lda (ptr2),y
    beq :+
    nop
    sta (ptr1),z
    inz
    iny
    bne :-

:   ldq ptr1
    rts
.endproc
