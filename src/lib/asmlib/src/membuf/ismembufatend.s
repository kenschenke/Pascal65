;
; ismembufatend.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; isMemBufAtEnd routine

.include "membufasm.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export isMemBufAtEnd

.import ltUint16

; Sets Z flag if membuf is at the end
; Membuf pointer passed in Q
.proc isMemBufAtEnd
    stq ptr1
    ; Copy posGlobal to intOp1
    ldz #MEMBUF::posGlobal
    nop
    lda (ptr1),z
    sta intOp1
    inz
    nop
    lda (ptr1),z
    sta intOp1+1
    ; Copy used to intOp2
    ldz #MEMBUF::used
    nop
    lda (ptr1),z
    sta intOp2
    inz
    nop
    lda (ptr1),z
    sta intOp2+1
    jmp ltUint16
.endproc
