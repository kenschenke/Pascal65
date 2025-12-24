;
; verifyFwdDeclarations.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; verifyFwdDeclarations routine

.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

declOffset = 0
stmtOffset = 0

.export verifyFwdDeclarations

.import currentLineNumber, resolverError

; AST root passed in Q
.proc verifyFwdDeclarations
    jsr pushQ
    ; Fall through to verifyDecl
.endproc

; Declaration at top of runtime stack
.proc verifyDecl
L1: jsr loadDecl
    jsr isQZero
    bne :+
    jmp L5

:   ldz #decl::lineNumber
    nop
    lda (ptr1),z
    sta currentLineNumber
    inz
    nop
    lda (ptr1),z
    sta currentLineNumber+1

    ldz #decl::name
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L3
    stq ptr4

    ldz #decl::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    ldz #type::flags
    nop
    lda (ptr2),z
    and #TYPE_FLAG_ISFORWARD
    beq L3
    ldz #type::kind
    nop
    lda (ptr2),z
    cmp #TYPE_PROCEDURE
    beq L2
    cmp #TYPE_FUNCTION
    bne L3

L2: jsr scopeLookup
    jsr isQZero
    bne L3
    stq ptr2
    jsr loadDecl
    ldz #symbol::decl
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr3
    ; compare ptr1 to ptr3
    ldx #0
:   lda ptr1,x
    cmp ptr3,x
    bne L3
    inx
    cpx #4
    bne :-
    lda #errUnresolvedFwd
    jsr resolverError

L3: jsr loadDecl
    ldz #decl::code
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L4
    stq ptr2

    ldz #decl::symtab
    neg
    neg
    nop
    lda (ptr1),z
    jsr scopeEnterSymtab

    ldq ptr2
    jsr pushQ
    jsr verifyStmt

    jsr scopeExit

L4: jsr loadDecl
    ldz #decl::next
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #declOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    jmp L1

L5: jsr popQ
    rts
.endproc

; Verify the declarations in a statement block
; First statement on stack
.proc verifyStmt
L1: jsr loadDecl
    jsr isQZero
    beq L2

    ldz #stmt::decl
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ
    jsr verifyDecl

    jsr loadDecl
    ldz #stmt::next
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #stmtOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    bra L1

L2: jsr popQ
    rts
.endproc

; This routine loads the current declaration pointer from the stack into ptr1
.proc loadDecl
    ldz #declOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    rts
.endproc
