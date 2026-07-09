;
; exprClone.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; exprClone routine

.include "ast.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export exprClone

.import savePtrs, restorePtrs, storePtr, symbolClone, typeClone
.import heapAlloc, isQZero, rtPushQ, rtPopQ

.proc exprClone
    jsr isQZero
    bne :+
    rts

:   jsr rtPushQ

    ; Allocate a expr structure and store the pointer in ptr2
    lda #.sizeof(expr)
    ldx #0
    jsr heapAlloc
    stq ptr2

    ; Zero out the new expr
    lda #0
    ldz #0
:   nop
    sta (ptr2),z
    inz
    cpz #.sizeof(expr)
    bne :-

    ; Put the original structure pointer in ptr1
    jsr rtPopQ
    stq ptr1

    ; Copy the kind
    ldz #expr::kind
    nop
    lda (ptr1),z
    nop
    sta (ptr2),z

    ; Clone the left expr
    jsr savePtrs
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    jsr exprClone
    stq ptr3
    jsr restorePtrs
    ldz #expr::left
    jsr storePtr
    
    ; Clone the right expr
    jsr savePtrs
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    jsr exprClone
    stq ptr3
    jsr restorePtrs
    ldz #expr::right
    jsr storePtr

    ; Copy the name
    ldz #expr::name
    ldx #0
:   nop
    lda (ptr1),z
    nop
    sta (ptr2),z
    inz
    inx
    cpx #NAMELEN
    bne :-

    ; Clone the symbol table node
    jsr savePtrs
    ldz #expr::node
    neg
    neg
    nop
    lda (ptr1),z
    jsr symbolClone
    stq ptr3
    jsr restorePtrs
    ldz #expr::node
    jsr storePtr

    ; Clone the neg byte
    ldz #expr::neg
    nop
    lda (ptr1),z
    nop
    sta (ptr1),z

    ; Clone the width expr
    jsr savePtrs
    ldz #expr::width
    neg
    neg
    nop
    lda (ptr1),z
    jsr exprClone
    stq ptr3
    jsr restorePtrs
    ldz #expr::width
    jsr storePtr

    ; Clone the precision expr
    jsr savePtrs
    ldz #expr::precision
    neg
    neg
    nop
    lda (ptr1),z
    jsr exprClone
    stq ptr3
    jsr restorePtrs
    ldz #expr::precision
    jsr storePtr

    ; Clone the evalType
    jsr savePtrs
    ldz #expr::evalType
    neg
    neg
    nop
    lda (ptr1),z
    jsr typeClone
    stq ptr3
    jsr restorePtrs
    ldz #expr::evalType
    jsr storePtr

    ; Copy the value
    ldz #expr::value
    ldx #0
:   nop
    lda (ptr1),z
    nop
    sta (ptr2),z
    inz
    inx
    cpx #4
    bne :-

    ; Copy the lineNumber value
    ldz #expr::lineNumber
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
