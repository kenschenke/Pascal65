;
; stmtCreate.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; stmtCreate routine

.include "ast.inc"
.include "zeropage.inc"
.include "4510macros.inc"

kindOffset = 10
exprOffset = 6
bodyOffset = 2
lineNumberOffset = 0

.export stmtCreate

.import storeFromStack, rtPopA, rtPopAX, rtPopQ, heapAlloc

; Allocate a stmt structure and populate it with parameters.
; Inputs on runtime stack, bottom to top:
;    STMT_* type   - 1 byte
;    expr pointer  - 4 bytes
;    body pointer  - 4 bytes
;    lineNumber    - 2 bytes
; Returns pointer to stmt structure in Q
.proc stmtCreate
    ; Allocate the structure
    lda #.sizeof(stmt)
    ldx #0
    jsr heapAlloc
    stq ptr1

    ; Zero out the stmt structure
    lda #0
    ldz #.sizeof(stmt)-1
:   nop
    sta (ptr1),z
    dez
    bpl :-

    ; Store the stmt kind
    ldz #kindOffset
    nop
    lda (stackPointer),z
    ldz #stmt::kind
    nop
    sta (ptr1),z

    ; Store the expr pointer
    lda #exprOffset
    ldx #stmt::expr
    jsr storeFromStack

    ; Store the body pointer
    lda #bodyOffset
    ldx #stmt::body
    jsr storeFromStack

    jsr rtPopAX
    ldz #stmt::lineNumber
    nop
    sta (ptr1),z
    inz
    txa
    nop
    sta (ptr1),z

    ; Pop the parameters off the stack
    jsr rtPopQ
    jsr rtPopQ
    jsr rtPopA

    ldq ptr1
    rts
.endproc
