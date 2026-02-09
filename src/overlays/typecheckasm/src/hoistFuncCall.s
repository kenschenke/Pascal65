;
; hoistFuncCall.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export hoistFuncCall

.bss

callExprPtr: .res 4
nameExprPtr: .res 4

.code

; This routine takes a bare EXPR_NAME structure and replaces its
; contents with an EXPR_CALL structure.
; Expression passed in Q.
.proc hoistFuncCall
    ; Save the existing EXPR_NAME ptr
    jsr pushQ

    ; First, allocate a new expression and copy the contents of the
    ; existing expression into it.
    lda #.sizeof(expr)
    ldx #0
    jsr heapAlloc
    stq ptr1
    stq nameExprPtr
    jsr popQ
    stq ptr2
    stq callExprPtr
    ; Copy ptr2 to ptr1
    ldz #0
:   nop
    lda (ptr2),z
    nop
    sta (ptr1),z
    inz
    cpz #.sizeof(type)
    bne :-

    ; Convert the original EXPR_NAME into a EXPR_CALL
    ldq callExprPtr
    stq ptr1
    ; expression kind
    ldz #expr::kind
    lda #EXPR_CALL
    nop
    sta (ptr1),z
    ; expression left (points to original EXPR_NAME)
    ldz #expr::left
    ldx #0
:   lda nameExprPtr,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    ; expression right (null)
    lda #0
    ldz #expr::right
    ldx #0
:   nop
    sta (ptr1),z
    inx
    inz
    cpx #4
    bne :-
    ; expression name (null)
    ldz #expr::name
    ldx #0
:   nop
    sta (ptr1),z
    inx
    inz
    cpx #4
    bne :-
    ; expression node (null)
    ldz #expr::node
    ldx #0
:   nop
    sta (ptr1),z
    inx
    inz
    cpx #4
    bne :-
    rts
.endproc
