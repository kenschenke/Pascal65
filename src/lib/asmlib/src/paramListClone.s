;
; paramListClone.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; paramListClone routine

.include "ast.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export paramListClone

.import savePtrs, restorePtrs, storePtr, nameClone, typeClone
.import isQZero, heapAlloc, rtPushQ, rtPopQ

.proc paramListClone
    jsr isQZero
    bne :+
    rts

:   jsr rtPushQ

    ; Allocate a param_list structure and store the pointer in ptr2
    lda #.sizeof(param_list)
    ldx #0
    jsr heapAlloc
    stq ptr2

    ; Zero out the new param_list
    lda #0
    ldz #0
:   nop
    sta (ptr2),z
    inz
    cpz #.sizeof(param_list)
    bne :-

    ; Put the original structure pointer in ptr1
    jsr rtPopQ
    stq ptr1

    ; Copy the name
    ldz #param_list::name
    ldx #0
:   nop
    lda (ptr1),z
    nop
    sta (ptr2),z
    inz
    inx
    cpx #NAMELEN
    bne :-

    ; Clone the type
    jsr savePtrs
    ldz #param_list::type
    neg
    neg
    nop
    lda (ptr1),z
    jsr typeClone
    stq ptr3
    jsr restorePtrs
    ldz #param_list::type
    jsr storePtr

    ; Clone next
    jsr savePtrs
    ldz #param_list::next
    neg
    neg
    nop
    lda (ptr1),z
    jsr paramListClone
    stq ptr3
    jsr restorePtrs
    ldz #param_list::next
    jsr storePtr

    ; Copy lineNumber
    ldz #param_list::lineNumber
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
