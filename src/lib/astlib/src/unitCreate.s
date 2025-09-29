.include "ast.inc"
.include "asmlib.inc"
.include "4510macros.inc"
.include "zeropage.inc"

.export unitCreate

; Unit name passed in A/X
.proc unitCreate
    jsr pushAX              ; save name on runtime stack
    lda #.sizeof(unit)
    ldx #0
    jsr heapAlloc
    stq ptr1

    ; Zero out the structure
    ldx #.sizeof(unit)-1
    lda #0
:   nop
    sta (ptr1),z
    dez
    bpl :-

    ; Copy the name into the structure
    jsr popAX
    sta ptr2
    stx ptr2+1
    ldz #unit::name
    ldy #0
:   lda (ptr2),y
    beq :+
    nop
    sta (ptr1),z
    iny
    inz
    bne :-
:   ldq ptr1
    rts
.endproc
