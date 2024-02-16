; String routines

.include "types.inc"
.include "runtime.inc"
.include "error.inc"
.include "cbm_kernal.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp readStringFromInput

; end of exports
.byte $00, $00, $00

; imports

skipSpaces: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

strPtr: .res 2

; This routine reads a string of characters from the input
; and stores them in a string variable.  It skips spaces in
; the input until the first non-space.
;
; Inputs
;   A - nesting level of string variable
;   X - value offset on runtime stack
.proc readStringFromInput
    jsr rtCalcStackOffset
    lda ptr1
    sta strPtr
    lda ptr1 + 1
    sta strPtr + 1
    ; Free existing heap for string
    ldy #1
    lda (ptr1),y
    tax
    dey
    lda (ptr1),y
    jsr rtHeapFree
    jsr skipSpaces          ; Skip over spaces in the input buffer
    ; Calculate length of input
    lda inputBufUsed
    sec
    sbc inputPos
    ldx #0
    pha                     ; Save length of string buffer
    adc #1                  ; Add 1 for string length
    jsr rtHeapAlloc
    sta ptr2
    stx ptr2 + 1
    ldy #0
    pla
    sta (ptr2),y
    tax
:   lda (inputBuf),y
    iny
    sta (ptr2),y
    dex
    bne :-
    lda strPtr
    sta ptr1
    lda strPtr + 1
    sta ptr1 + 1
    ldy #0
    lda ptr2
    sta (ptr1),y
    iny
    lda ptr2 + 1
    sta (ptr1),y
    rts
.endproc

