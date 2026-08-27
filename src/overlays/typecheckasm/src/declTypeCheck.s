;
; declTypeCheck.s
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

declOffset = 0

.export declTypeCheck

.import currentLineNumber, declTypeCheckValue, stmtTypeCheck, declTypeCheckType
.import loadStackValue

; Address of decl in Q
.proc declTypeCheck
    jsr isQZero
    bne :+
    rts

:   jsr pushQ               ; Save declaration on the CPU stack

    ; Loop through the declarations
L1: ldz #declOffset
    jsr loadStackValue
    stq ptr1
    jsr isQZero
    bne :+
    jmp L5
:   ldz #decl::lineNumber
    jsr getDeclMember
    sta currentLineNumber
    stx currentLineNumber+1

    ; Check the decl's value
    ldz #decl::value
    jsr getDeclMember
    jsr isQZero
    beq L2
    jsr declTypeCheckValue
    ldz #declOffset
    jsr loadStackValue
    stq ptr1

    ; Check the decl's stmt body
L2: ldz #decl::code
    jsr getDeclMember
    jsr isQZero
    beq L3
    ; Does the decl have a symbol table?
    ldz #decl::symtab
    jsr getDeclMember
    jsr isQZero
    beq :+
    jsr scopeEnterSymtab
    ; Check the stmt body
:   ldz #decl::code
    jsr getDeclMember
    jsr stmtTypeCheck
    ; Restore the declaration
    ldz #declOffset
    jsr loadStackValue
    stq ptr1
    ; Does the decl have a symbol table?
    ldz #decl::symtab
    jsr getDeclMember
    jsr isQZero
    beq L3
    jsr scopeExit
 
    ; Check the decl's type
L3: ldz #declOffset
    jsr loadStackValue
    stq ptr1
    ldz #decl::type
    jsr getDeclMember
    jsr isQZero
    beq L4
    jsr declTypeCheckType

    ; Move to the next declaration
L4: ldz #declOffset
    jsr loadStackValue
    stq ptr1
    ldz #decl::next
    jsr getDeclMember
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

; This routine loads a decl member from the structure into Q.
; The offset in passed in Z.
.proc getDeclMember
    neg
    neg
    nop
    lda (ptr1),z
    rts
.endproc
