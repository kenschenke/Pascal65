;
; checkIntegerBaseType.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

typeOffset = 0
exprOffset = typeOffset + .sizeof(type)

.export checkIntegerBaseType

.import loadStackValue, exprTypeCheck, typeCheckError, isTypeInteger

; This routine type checks an expression and reports an error if its type
; is not one of the integer types (any size, signed or unsigned). A null
; expression is not checked.
;
; Parameters on the stack, bottom to top:
;    expression ptr
.proc checkIntegerBaseType
    ; The expression's type goes in a block on the runtime stack so that
    ; this routine can be called again while checking the expression.
    lda #.sizeof(type)
    jsr pushBlock
    ldz #typeOffset
    lda #0
:   nop
    sta (stackPointer),z
    inz
    cpz #.sizeof(type)
    bne :-

    ldq stackPointer            ; the type block is at the stack pointer
    stq ptr1
    ldz #exprOffset
    jsr loadStackValue
    jsr isQZero
    beq DN

    jsr pushQ                   ; expression
    jsr pushQZero               ; record symbol table
    ldq ptr1
    jsr pushQ                   ; type
    lda #0
    jsr pushA                   ; parentIsFuncCall
    jsr exprTypeCheck

    ldq stackPointer
    jsr getBaseType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    jsr isTypeInteger
    beq DN
    lda #errIncompatibleTypes
    jsr typeCheckError

DN: lda #.sizeof(type)
    jsr popBlock
    jsr popQ
    rts
.endproc
