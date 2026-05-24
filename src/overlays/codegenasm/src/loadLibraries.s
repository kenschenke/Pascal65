;
; loadLibraries.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; loadLibraries routine

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export loadLibraries

.import loadLibrary, findUnit

.bss

currentDecl: .res 4
unitName: .res 4

.code

; AST root passed in Q
.proc loadLibraries
    stq ptr1

    ; Grab the code block from the root node
    ldz #decl::code
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1

    ; Grab the first declaration from the code block
    ldz #stmt::decl
    neg
    neg
    nop
    lda (ptr1),z
    stq currentDecl

    ; Loop through the declarations
L1: ldq currentDecl
    jsr isQZero
    bne L2
    rts

L2: stq ptr1
    ; Is the kind DECL_USES?
    ldz #decl::kind
    nop
    lda (ptr1),z
    cmp #DECL_USES
    bne NX

    ldz #decl::name
    neg
    neg
    nop
    lda (ptr1),z
    stq unitName
    jsr findUnit
    jsr isQZero
    beq NX

    stq ptr1            ; ptr1 is unit
    ldz #unit::astRoot
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2            ; ptr2 is unit decl

    ldz #decl::isLibrary
    nop
    lda (ptr2),z
    beq NX

    ; Load the library
    ; name in ptr1
    ; unit AST root in ptr2
    ldq unitName
    stq ptr1
    jsr loadLibrary

NX: ldq currentDecl
    stq ptr1
    ldz #decl::next
    neg
    neg
    nop
    lda (ptr1),z
    stq currentDecl
    jmp L1

    rts
.endproc
