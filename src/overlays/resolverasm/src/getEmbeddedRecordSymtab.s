;
; getEmbeddedRecordSymtab.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; getEmbeddedRecordSymtab routine

.include "ast.inc"
.include "asmlib.inc"
.include "error.inc"
.include "zeropage.inc"
.include "4510macros.inc"

symtabOffset = 0
fieldExprOffset = symtabOffset + 4
recExprOffset = fieldExprOffset + 4

.export getEmbeddedRecordSymtab

.import getRecordSymtab, typeRecordSymtab

; On entry, runtime stack bottom to top
;    record expression ptr
;    field expression ptr
;    record symbol table
.proc getEmbeddedRecordSymtab
    ldz #recExprOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #symtabOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr2
    ldq ptr1
    jsr pushQ
    ldq ptr2
    jsr pushQ
    jsr getRecordSymtab
    stq ptr1
    ldz #fieldExprOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr2
    ldz #expr::name
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr4
    jsr symtabLookup
    jsr isQZero
    bne :+
    ; Not a field of the record. exprResolve reports it.
    jsr popQ
    jsr popQ
    jsr popQ
    lda #0
    tax
    tay
    taz
    rts
    ; The field's record: its type, an element of it or what it points to
:   stq ptr1
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr1),z
    jsr typeRecordSymtab
    stq ptr1
    jsr popQ
    jsr popQ
    jsr popQ
    ldq ptr1
    rts
.endproc
