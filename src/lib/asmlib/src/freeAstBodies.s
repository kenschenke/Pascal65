;
; freeAstBodies.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; astFreeBodies routine

.include "ast.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export astFreeBodies

.import freeStmt, freeExpr, loadPtr, peekQ, rtPushQ, rtPopQ, isQZero

; This routine frees the parts of an AST that are only needed up to the point
; intermediate code has been generated: the statements in the body of the
; program and of every routine, and the value expression of every declaration.
; The declarations themselves, their types, and the symbol tables are left alone
; because code generation still reads them. astFree frees everything later and
; skips the pointers that were cleared here.
;
; Pointer to the program, unit, or routine declaration passed in Q.
.proc astFreeBodies
    jsr isQZero
    bne :+
    rts

:   jsr rtPushQ                 ; the declaration
    jsr peekQ
    stq ptr1
    ldz #decl::code
    jsr loadPtr
    jsr isQZero
    beq DN

    jsr rtPushQ                 ; the code block
    ; Free the statements
    jsr peekQ
    stq ptr1
    ldz #stmt::body
    jsr loadPtr
    jsr freeStmt
    jsr peekQ
    stq ptr1
    ldz #stmt::body
    jsr clearPtr

    ; Free what is in the declarations in this block
    jsr peekQ
    stq ptr1
    ldz #stmt::decl
    jsr loadPtr
    jsr declChainBodies
    jsr peekQ
    stq ptr1
    ldz #stmt::interfaceDecl
    jsr loadPtr
    jsr declChainBodies
    jsr rtPopQ                  ; discard the code block

DN: jsr rtPopQ                  ; discard the declaration
    rts
.endproc

; Frees the value of each declaration in a chain and the bodies of any
; routines in it. Pointer to the first declaration passed in Q.
.proc declChainBodies
    jsr rtPushQ
L1: jsr peekQ
    jsr isQZero
    bne L2
    jsr rtPopQ
    rts

L2: jsr peekQ
    stq ptr1
    ldz #decl::value
    jsr loadPtr
    jsr freeExpr
    jsr peekQ
    stq ptr1
    ldz #decl::value
    jsr clearPtr

    jsr peekQ
    jsr astFreeBodies

    ; Move to the next declaration
    jsr rtPopQ
    stq ptr1
    ldz #decl::next
    jsr loadPtr
    jsr rtPushQ
    bra L1
.endproc

; Sets the 4-byte pointer at offset Z in the structure at ptr1 to zero.
.proc clearPtr
    lda #0
    ldx #4
:   nop
    sta (ptr1),z
    inz
    dex
    bne :-
    rts
.endproc
