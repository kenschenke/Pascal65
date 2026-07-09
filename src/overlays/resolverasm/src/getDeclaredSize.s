;
; getDeclaredSize.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; getDeclaredSize routine

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export getDeclaredSize

.import getTypeSize, calcNamePtr

; Type is in ptr1
; Size returned in A/X
.proc getDeclaredSize
    ldq ptr1
    ldz #type::name
    jsr calcNamePtr
    stq ptr4
    jsr scopeLookup
    jsr isQZero
    beq L1
    stq ptr1
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr1),z
    jsr getTypeSize
L1: rts
.endproc
