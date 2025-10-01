.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

firstDeclOffset = 4
lastDeclOffset = 0

.export appendDecl

; This routine appends the declaration in ptr2 to the list of
; declarations.
;
; Is is assumed that the pointer to firstDecl is offset 4
; on the runtime stack and the value of lastDecl is at the
; bottom of the runtime stack.
.proc appendDecl
    ; See if firstDecl is null
    ldz #firstDeclOffset
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1                    ; Pointer to firstDecl on runtime stack
    ldz #0
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero                 ; Is firstDecl null?
    bne L2                      ; Branch if so
    ; firstDecl is null
    ldz #0
    ldx #0
:   lda ptr2,x                  ; Copy ptr2 to firstDecl
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    bra L3
    rts
L2: ; Append declaration to the last one
    ldz #lastDeclOffset         ; Set lastDecl's next to new declaration
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #decl::next
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    ; Set lastDecl to the new declaration
L3: ldz #lastDeclOffset
    ldx #0
:   lda ptr2,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    rts
.endproc
