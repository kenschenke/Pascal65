;
; unitCreate.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; unitCreate routine

.include "ast.inc"
.include "4510macros.inc"
.include "zeropage.inc"

.export unitCreate

.import rtPushAX, heapAlloc, rtPopAX

; Unit name passed in A/X
.proc unitCreate
    jsr rtPushAX              ; save name on runtime stack
    lda #.sizeof(unit)
    ldx #0
    jsr heapAlloc
    stq ptr1

    ; Zero out the structure
    ldz #.sizeof(unit)-1
    lda #0
:   nop
    sta (ptr1),z
    dez
    bpl :-

    ; Copy the name into the structure
    jsr rtPopAX
    sta ptr2
    stx ptr2+1
    ldz #unit::name
    ldy #0
:   lda (ptr2),y
    beq :+
    nop
    sta (ptr1),z
    iny
    inz
    bne :-
:   ldq ptr1
    rts
.endproc
