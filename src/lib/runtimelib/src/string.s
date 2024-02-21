; String routines

.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp duplicateString

; end of exports
.byte $00, $00, $00

; imports

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

srcPtr: .res 2
strPtr: .res 2

; This routine makes a copy of the string in A/X.
; The new string is returned in A/X.
; ptr1 and ptr2 are destroyed.
.proc duplicateString
    sta srcPtr
    sta ptr1
    stx srcPtr + 1
    stx ptr1 + 1
    ldy #0
    lda (ptr1),y
    pha
    ldx #0
    jsr rtHeapAlloc
    sta strPtr
    sta ptr2
    stx strPtr + 1
    stx ptr2 + 1
    lda srcPtr
    sta ptr1
    lda srcPtr + 1
    sta ptr1 + 1
    ldy #0
    pla
    sta (ptr2),y
    tax
:   iny
    lda (ptr1),y
    sta (ptr2),y
    dex
    bne :-
    lda strPtr
    ldx strPtr + 1
    rts
.endproc
