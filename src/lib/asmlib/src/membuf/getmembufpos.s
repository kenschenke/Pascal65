;
; getmembufpos.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; getMemBufPos routine

.include "membufasm.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export getMemBufPos

; Membuf pointer passed in Q
; Position returned in A/X
.proc getMemBufPos
    stq ptr1
    ldz #MEMBUF::posGlobal+1
    nop
    lda (ptr1),z
    tax
    dez
    nop
    lda (ptr1),z
    rts
.endproc
