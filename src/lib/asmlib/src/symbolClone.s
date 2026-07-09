;
; symbolClone.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; symbolClone routine

.include "ast.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export symbolClone

.import savePtrs, restorePtrs, storePtr, declClone, typeClone
.import isQZero, heapAlloc, rtPushQ, rtPopQ

.proc symbolClone
    jsr isQZero
    bne :+
    rts

:   jsr rtPushQ

    ; Allocate a symbol structure and store the pointer in ptr2
    lda #.sizeof(symbol)
    ldx #0
    jsr heapAlloc
    stq ptr2

    ; Zero out the new symbol
    lda #0
    ldz #0
:   nop
    sta (ptr2),z
    inz
    cpz #.sizeof(symbol)
    bne :-

    ; Put the original structure pointer in ptr1
    jsr rtPopQ
    stq ptr1

    ; Clone the type
    jsr savePtrs
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr1),z
    jsr typeClone
    stq ptr3
    jsr restorePtrs
    ldz #symbol::type
    jsr storePtr

    ; Copy the name
    ldz #symbol::name
    ldx #0
:   nop
    lda (ptr1),z
    nop
    sta (ptr2),z
    inz
    inx
    cpx #NAMELEN
    bne :-

    ; Copy which
    ldz #symbol::which
    nop
    lda (ptr1),z
    nop
    sta (ptr2),z
    inz
    nop
    lda (ptr1),z
    nop
    sta (ptr2),z

    ; Copy offset
    ldz #symbol::offset
    nop
    lda (ptr1),z
    nop
    sta (ptr2),z
    inz
    nop
    lda (ptr1),z
    nop
    sta (ptr2),z

    ; Copy level
    ldz #symbol::level
    nop
    lda (ptr1),z
    nop
    sta (ptr2),z
    inz
    nop
    lda (ptr1),z
    nop
    sta (ptr2),z

    ldq ptr2
    rts
.endproc
