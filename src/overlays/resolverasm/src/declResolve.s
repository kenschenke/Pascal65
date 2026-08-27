;
; declResolve.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; declResolve routine

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

declOffset = 8
symtabOffset = 4
membufOffset = 0

.export declResolve

.import resolveDeclaration

; This routine is passed a pointer to a declaration structure.
; It also happens to be the main entry point to the resolver overlay.
; The root node of the AST is a declaration.
;
; This routine resolves all declarations in a chain by following
; the "next" pointer.
;
; The routine expects a few things on the runtime stack from bottom
; to top:
;
;    declPointer - Pointer to initial declaration (updated in loop)
;    symtabPointer - Pointer to symbol table pointer
.proc declResolve
    jsr pushQZero           ; membuf

L1: ldz #declOffset
    neg
    neg
    nop
    lda (stackPointer),z
    jsr isQZero
    bne :+
    jmp L9

    ; Put the parameters for resolveDeclaration on the stack
:   stq ptr1
    ldq stackPointer
    clc
    adcq #membufOffset
    stq ptr2
    ldz #symtabOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr3

    ldq ptr1
    jsr pushQ
    ldq ptr2
    jsr pushQ
    ldq ptr3
    jsr pushQ
    lda #1
    jsr pushA
    jsr resolveDeclaration

    ldz #declOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #decl::next
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldx #0
    ldz #declOffset
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    bra L1

    ; If any of the declarations could not be resolved, they are stored in
    ; a temporary buffer. Go through those again and make another attempt.
    ldz #membufOffset
    neg
    neg
    nop
    lda (stackPointer),z
    jsr isQZero
    beq L9

    stq ptr1
    lda #0
    tax
    jsr setMemBufPos

    ; Loop through the membuf and make another run at resolving the declaration.
L2: ldz #membufOffset
    neg
    neg
    nop
    lda (stackPointer),z
    jsr isMemBufAtEnd
    beq L3

    ; Read the declaration pointer from the membuf
    ldq stackPointer
    clc
    adcq #declOffset
    stq ptr2
    lda #4
    ldx #0
    jsr readFromMemBuf

    ; Prepare the arguments for resolveDeclaration for the stack
    ldz #declOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #symtabOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr2
    ldq ptr1
    jsr pushQ
    jsr pushQZero
    ldq ptr2
    jsr pushQ
    lda #0
    jsr pushA
    jsr resolveDeclaration
    bra L2

L3: ldz #membufOffset
    neg
    neg
    nop
    lda (stackPointer),z
    jsr freeMemBuf

L9: jsr popQ            ; membuf
    jsr popQ            ; symtab pointer
    jsr popQ            ; declaration pointer
    rts
.endproc
