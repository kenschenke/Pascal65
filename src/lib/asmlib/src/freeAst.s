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

.import freeDecl

.proc freeAst
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
