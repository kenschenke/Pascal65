; String routines

.include "types.inc"
.include "runtime.inc"
.include "error.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp assignString

; end of exports
.byte $00, $00, $00

; imports

convertString: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

srcPtr: .res 2
varPtr: .res 2

; This routine assigns one string to another.
; The left side will always be a newly allocated string.
; The routine expects ptr1 to contain a pointer to the
; variable's position on the runtime stack. The heap 
; pointed to by that position will be free'd and a new
; heap allocated.
; The right side can be one of:
;   a) Another string (variable or object)
;   b) A string literal
;   c) An array of char
;   d) A character literal
; The right type is pushed onto the stack
; and then the pointer to the variable on the stack is pushed onto the stack.
; The pointer to the right value is passed in A/X
;   srcPtr - pointer to source
;   varPtr - pointer to variable on stack
.proc assignString
    sta srcPtr              ; Save the source pointer
    stx srcPtr + 1
    jsr rtPopAx
    sta varPtr              ; Save the pointer to the string variable
    sta ptr1
    stx varPtr + 1
    stx ptr1 + 1
    jsr rtPopAx
    pha                     ; Save the source type
    ; Free the current string variable
    ldy #1
    lda (ptr1),y
    tax
    dey
    lda (ptr1),y
    jsr rtHeapFree
    pla                     ; Pop the source type
    tay                     ; and move it to Y
    lda srcPtr
    ldx srcPtr + 1
    jsr convertString
    sta tmp1                ; Save the new string ptr in tmp1/tmp2
    stx tmp2
    lda varPtr
    sta ptr1
    lda varPtr + 1
    sta ptr1 + 1
    ldy #0
    lda tmp1
    sta (ptr1),y
    iny
    lda tmp2
    sta (ptr1),y
    rts
.endproc

