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

declOffset = 4
symtabOffset = 0

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
L1: ldz #declOffset
    neg
    neg
    nop
    lda (stackPointer),z
    jsr isQZero
    beq L9

    ; Put the parameters for resolveDeclaration on the stack
    stq ptr1
    ldz #symtabOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr3

    ldq ptr1
    jsr pushQ               ; declaration
    jsr pushQZero           ; not used
    ldq ptr3
    jsr pushQ               ; symbol table pointer
    lda #1
    jsr pushA               ; fail if the name exists
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

L9: jsr popQ            ; symtab pointer
    jsr popQ            ; declaration pointer
    rts
.endproc
