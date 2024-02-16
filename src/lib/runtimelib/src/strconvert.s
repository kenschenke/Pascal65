; String conversion

.include "types.inc"
.include "runtime.inc"
.include "error.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp convertString

; end of exports
.byte $00, $00, $00

; imports

subInt16: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

srcPtr: .res 2

.proc convertCharLiteral
    lda #2
    ldx #0
    jsr rtHeapAlloc
    sta ptr4
    stx ptr4 + 1
    ldy #0
    lda #1
    sta (ptr4),y
    iny
    lda srcPtr
    sta (ptr4),y
    lda ptr4
    ldx ptr4 + 1
    rts
.endproc

; This routine converts a compatible input to a string.
; The left side will always be a newly allocated string.
; The right side can be one of:
;   a) Another string (variable or object)
;   b) A string literal
;   c) An array of char
;   d) A character literal
; The pointer to the right value is passed in A/X
; The source type is passed in Y
;   ptr1 - pointer to source
;   srcPtr - pointer to source
;   ptr4 - pointer to destination
; Newly allocated string returned in A/X.
.proc convertString
    sta srcPtr
    stx srcPtr + 1
    tya
    cmp #TYPE_STRING_VAR
    beq convertStrVar
    cmp #TYPE_STRING_OBJ
    beq convertStrVar
    cmp #TYPE_STRING_LITERAL
    beq convertStrLiteral
    cmp #TYPE_CHARACTER
    beq convertCharLiteral
    ; Convert array of chars
    lda srcPtr
    sta ptr3
    lda srcPtr + 1
    sta ptr3 + 1
    ldy #0
    lda (ptr3),y            ; Load array low bound into intOp2
    sta intOp2
    iny
    lda (ptr3),y
    sta intOp2 + 1
    iny
    lda (ptr3),y            ; Load array upper bound into intOp1
    sta intOp1
    iny
    lda (ptr3),y
    sta intOp1 + 1
    jsr subInt16            ; Subtract intOp2 from intOp1 (length of array)
    lda intOp1 + 1          ; Look at high byte of array length
    beq :+                  ; Branch if array <= 255
    lda #rteStringOverflow
    jsr rtRuntimeError
:   inc intOp1              ; Length is actually upper - lower + 1
    lda ptr3                ; Adjust srcPtr to first array element
    clc
    adc #6
    sta srcPtr
    lda ptr3 + 1
    adc #0
    sta srcPtr + 1
    lda intOp1
    jmp copyString
.endproc

.proc convertStrVar
    ldy #0
    lda srcPtr
    sta ptr3
    lda srcPtr + 1
    sta ptr3 + 1
    lda (ptr3),y            ; Load source string length
    pha                     ; Save it
    lda srcPtr              ; Adjust srcPtr to first char of source
    clc
    adc #1
    sta srcPtr
    lda srcPtr + 1
    adc #0
    sta srcPtr + 1
    pla                     ; Pop the source string length
    jmp copyString
.endproc

.proc convertStrLiteral
    lda srcPtr
    sta ptr3
    lda srcPtr + 1
    sta ptr3 + 1
    ldy #0
:   lda (ptr3),y            ; Count the chars in the string literal
    beq :+
    iny
    bne :-
:   tya
    ; Fall through to copyString
.endproc

; Copy string
;    Source in ptr3
;    String length in A
.proc copyString
    pha             ; Save string length
    ldx #0
    clc
    adc #1
    jsr rtHeapAlloc ; Allocate memory for the destination
    sta ptr4        ; Save it in ptr4
    stx ptr4 + 1
    lda srcPtr      ; Set ptr3 again because heapAlloc changes it
    sta ptr3
    lda srcPtr + 1
    sta ptr3 + 1
    ldy #0
    pla             ; Pop the string length 
    sta (ptr4),y    ; Store it in first byte of string
    beq DN          ; Branch if empty string
    tax             ; Copy the length to X for the copy loop
:   lda (ptr3),y    ; Load the next byte from the source
    iny             ; Increment the index
    sta (ptr4),y    ; Store this byte in the destination
    dex             ; Decrement counter
    bne :-          ; Branch if still > 0
DN: lda ptr4        ; Load the destination into A/X
    ldx ptr4 + 1
    rts
.endproc

