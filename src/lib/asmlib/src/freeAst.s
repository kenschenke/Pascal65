;
; freeAst.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; freeAst routine

.include "zeropage.inc"

.export freeAst, loadPtr, peekQ

.import freeDecl, astFreeBodies, isQZero, rtPushQ, rtPopQ

.include "ast.inc"
.include "4510macros.inc"

; This routine frees the declaration in Q, and the ones after it in its
; chain, with everything in them. An expression's evaluated type shares
; the declared types (evalType.s), so every statement and value is freed
; first (astFreeBodies), while the types are still there. freeStmt frees a
; block's declarations before its statements, and once read the flags of
; types it had freed.
.proc freeAst
    jsr rtPushQ             ; the first declaration
    jsr peekQ               ; rtPushQ doesn't keep Q
    jsr rtPushQ             ; the one whose bodies are being freed
L1: jsr peekQ
    jsr isQZero
    beq L2
    jsr astFreeBodies
    jsr rtPopQ
    stq ptr1
    ldz #decl::next
    jsr loadPtr
    jsr rtPushQ
    bra L1

L2: jsr rtPopQ
    jsr rtPopQ
    sec
    jmp freeDecl
.endproc

; This routine loads a pointer from a structure in ptr1
; The structure offset is passed in Z.
.proc loadPtr
    neg
    neg
    nop
    lda (ptr1),z
    rts
.endproc

.proc peekQ
    ldz #0
    neg
    neg
    nop
    lda (stackPointer),z
    rts
.endproc
