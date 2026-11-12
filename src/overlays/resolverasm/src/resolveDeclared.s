;
; resolveDeclared.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; resolveDeclared routine

.include "ast.inc"
.include "error.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

; This routine runs in resolveDeclaration's stack frame
declOffset = 10

.export resolveDeclared

.import getTypePtr, resolverError, calcNamePtr

.proc resolveDeclared
    jsr getTypePtr
    ldz #type::name
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr4
    jsr scopeLookup
    jsr isQZero
    bne L2

    ; The type's name isn't declared
    lda #errInvalidType
    jmp resolverError

    ; The symbol is found
L2: stq ptr2            ; save symbol ptr
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr2),z        ; load the type pointer from the symbol

    jsr typeClone       ; clone the symbol type
    stq ptr2            ; cloned type in ptr2
    ldz #type::kind
    nop
    lda (ptr2),z
    cmp #TYPE_ENUMERATION
    bne L3
    ; Set the subtype
    jsr getTypePtr
    ; Copy the decl type into the cloned type's subtype
    ldq ptr2
    jsr pushQ
    ldq ptr1
    jsr typeClone
    stq ptr1
    jsr popQ
    stq ptr2
    ldz #type::subtype
    ldx #0
:   lda ptr1,x
    nop
    sta (ptr2),z
    inz
    inx
    cpx #4
    bne :-
    bra L4              ; skip freeing the current declaration's type
L3: ; Copy the size to the type of the declaration's symbol. Use the
    ; declaration's own symbol. Looking it up by name can't find the symbol
    ; of a record field, which is in the record's symbol table, not in scope.
    ldz #declOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #decl::node
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    bne :+
    jsr lookupDeclSymbol
    jsr isQZero
    beq L4                  ; no symbol
:   stq ptr1
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L4                  ; symbol has no type
    stq ptr1
    ldz #type::size
    nop
    lda (ptr2),z
    nop
    sta (ptr1),z
    inz
    nop
    lda (ptr2),z
    nop
    sta (ptr1),z
L4: ; Store the cloned type back into the declaration
    ldz #declOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #decl::type
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    stq ptr3
    ldq ptr1
    jsr pushQ
    ldq ptr2
    jsr pushQ
    ldq ptr3
    jsr freeType
    jsr popQ
    stq ptr2
    jsr popQ
    stq ptr1
:   ldz #decl::type
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inx
    inz
    cpx #4
    bne :-

    ; Save the type back into the symbol as well

    ; If there's no symbol, we're done.
    ldz #decl::node
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    bne :+
    rts

    ; If there's already a type in the symbol - free it.
:   stq ptr1
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L5

    stq ptr1                ; Store the old symbol type in ptr1

    ; If the type is ENUMERATION, leave it alone.
    ldq ptr1
    jsr pushQ
    ldq ptr2
    jsr pushQ
    ldq ptr1
    jsr getBaseType
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ENUMERATION
    bne :+
    jsr popQ
    jsr popQ
    rts

:   jsr popQ
    stq ptr2
    jsr popQ
    stq ptr1
    ldq ptr2
    jsr pushQ               ; Save the cloned type on the runtime stack
    ldq ptr1
    jsr freeType
    jsr popQ
    jsr typeClone           ; Clone the decl's type so the symbol has its own copy
    stq ptr2

    ; Load the declaration's symbol node back
    ldz #declOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #decl::node
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    
L5: ldz #symbol::type
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inx
    inz
    cpx #4
    bne :-
    rts
.endproc

; This routine looks up the symbol for the current declaration
; The pointer to the symbol is returned in Q.
.proc lookupDeclSymbol
    ldz #declOffset
    neg
    neg
    nop
    lda (stackPointer),z
    ldz #decl::name
    jsr calcNamePtr
    stq ptr4
    jsr scopeLookup
    rts
.endproc
