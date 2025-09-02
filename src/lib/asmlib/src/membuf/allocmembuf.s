;
; allocmembuf.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; allocMemBuf routine

.include "membufasm.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export allocMemBuf

.import heapAlloc

; This allocates a membuf header and returns the pointer in Q
.proc allocMemBuf
    ; Allocate memory for the header and store the pointer in ptr1
    lda #.sizeof(MEMBUF)
    ldx #0
    jsr heapAlloc
    stq ptr1

    ; Clear the header
    ldz #.sizeof(MEMBUF)-1
    lda #0
:   nop
    sta (ptr1),z
    dez
    bpl :-

    ; Return the pointer to the caller
    ldq ptr1
    rts
.endproc
