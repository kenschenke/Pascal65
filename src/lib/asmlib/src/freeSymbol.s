;
; freeSymbol.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; freeSymbol routine

.include "ast.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export freeSymbol

.import freeDecl, freeType, loadPtr, heapFree, rtPopQ, rtPushQ, isQZero
.import isHeapAllocated, peekQ

.bss

symPtr: .res 4

.code

.proc freeSymbol
    stq symPtr
    jsr isQZero
    bne :+
    rts
:   jsr isHeapAllocated
    bne :+
    rts
:   ldq symPtr
    stq ptr1
    jsr rtPushQ

    ; Node
    ldz #symbol::node
    jsr loadPtr
    sec
    jsr freeDecl

    ; Type
    jsr peekQ
    stq ptr1
    ldz #symbol::type
    jsr loadPtr
    jsr freeType

:   jsr rtPopQ
    jsr heapFree
    rts
.endproc
