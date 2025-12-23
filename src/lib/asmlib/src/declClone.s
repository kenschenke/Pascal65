;
; declClone.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; declClone routine

.include "ast.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export declClone

.import savePtrs, restorePtrs, storePtr, nameClone, typeClone
.import exprClone, symbolClone, stmtClone, heapAlloc
.import nameClone, rtPopQ, rtPushQ, isQZero

.proc declClone
    jsr isQZero
    bne :+
    rts

:   jsr rtPushQ

    ; Allocate a decl structure and store the pointer in ptr2
    lda #.sizeof(decl)
    ldx #0
    jsr heapAlloc
    stq ptr2

    ; Zero out the new decl
    lda #0
    ldz #0
:   nop
    sta (ptr2),z
    inz
    cpz #.sizeof(decl)
    bne :-

    ; Put the original structure pointer in ptr1
    jsr rtPopQ
    stq ptr1

    ; Copy the kind
    ldz #decl::kind
    nop
    lda (ptr1),z
    nop
    sta (ptr2),z

    ; Clone the name
    jsr savePtrs
    ldz #decl::name
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr3
    jsr isQZero
    beq :+
    jsr nameClone
    stq ptr3
:   jsr restorePtrs
    ldz #decl::name
    jsr storePtr

    ; Clone the type
    jsr savePtrs
    ldz #decl::type
    neg
    neg
    nop
    lda (ptr1),z
    jsr typeClone
    stq ptr3
    jsr restorePtrs
    ldz #decl::type
    jsr storePtr

    ; Clone the value
    jsr savePtrs
    ldz #decl::value
    neg
    neg
    nop
    lda (ptr1),z
    jsr exprClone
    stq ptr3
    jsr restorePtrs
    ldz #decl::value
    jsr storePtr

    ; Clone the symtab
    jsr savePtrs
    ldz #decl::symtab
    neg
    neg
    nop
    lda (ptr1),z
    jsr symbolClone
    stq ptr3
    jsr restorePtrs
    ldz #decl::symtab
    jsr storePtr

    ; Clone the code
    jsr savePtrs
    ldz #decl::code
    neg
    neg
    nop
    lda (ptr1),z
    jsr stmtClone
    stq ptr3
    jsr restorePtrs
    ldz #decl::code
    jsr storePtr

    ; Clone the unitSymtab
    jsr savePtrs
    ldz #decl::unitSymtab
    neg
    neg
    nop
    lda (ptr1),z
    jsr symbolClone
    stq ptr3
    jsr restorePtrs
    ldz #decl::unitSymtab
    jsr storePtr

    ; Copy the isLibrary byte
    ldz #decl::isLibrary
    nop
    lda (ptr1),z
    nop
    sta (ptr2),z

    ; Copy the line number
    ldz #decl::lineNumber
    nop
    lda (ptr1),z
    nop
    sta (ptr2),z
    inz
    nop
    lda (ptr1),z
    nop
    sta (ptr2),z

    ; Clone the next pointer
    jsr savePtrs
    ldz #decl::next
    neg
    neg
    nop
    lda (ptr1),z
    jsr declClone
    stq ptr3
    jsr restorePtrs
    ldz #decl::next
    jsr storePtr

    ldq ptr2
    rts
.endproc
