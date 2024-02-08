; String routines

.include "types.inc"
.include "runtime.inc"
.include "error.inc"
.include "cbm_kernal.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp assignString
jmp writeString
jmp concatString
jmp readStringFromInput
jmp stringSubscript

; end of exports
.byte $00, $00, $00

; imports

heapAlloc: jmp $0000
heapFree: jmp $0000
popax: jmp $0000
subInt16: jmp $0000
runtimeError: jmp $0000
leftpad: jmp $0000
addInt16: jmp $0000
popa: jmp $0000
skipSpaces: jmp $0000
calcStackOffset: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

srcPtr: .res 2
strPtr: .res 2

; These are the values for the two sides of a string concatenation.
;    a) Char array: ptr to array heap
;    b) Character: char value
;    c) String literal: pointer to string data
;    d) String variable: pointer to string heap
;    e) String object: pointer to string heap
concat1: .res 2
concat2: .res 2

type1: .res 1
type2: .res 1

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
; The pointer to the varible on the stack is pushed onto the stack
; and then the right type is pushed onto the stack
; The pointer to the right value is passed in A/X
;   ptr1 - pointer to string variable's position on stack
;   srcPtr - pointer to source
;   ptr4 - pointer to destination
.proc assignString
    sta srcPtr
    stx srcPtr + 1
    ; Keep a copy of ptr1
    jsr popax
    sta strPtr
    sta ptr1
    stx strPtr + 1
    stx ptr1 + 1
    ; Free the existing string for the variable
    ldy #1
    lda (ptr1),y
    tax
    dey
    lda (ptr1),y
    jsr heapFree
    jsr popax
    cmp #TYPE_STRING_VAR
    beq assignStrVar
    cmp #TYPE_STRING_OBJ
    beq assignStrVar
    cmp #TYPE_STRING_LITERAL
    beq assignStrLiteral
    ; Assign array of chars
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
    jsr runtimeError
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

.proc assignStrVar
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

.proc assignStrLiteral
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
    jsr heapAlloc   ; Allocate memory for the destination
    sta ptr4        ; Save it in ptr4
    stx ptr4 + 1
    lda srcPtr      ; Set ptr3 again because heapAlloc changes it
    sta ptr3
    lda srcPtr + 1
    sta ptr3 + 1
    lda strPtr      ; Update the variable to point to the new heap
    sta ptr1
    lda strPtr + 1
    sta ptr1 + 1
    ldy #0
    lda ptr4
    sta (ptr1),y
    iny
    lda ptr4 + 1
    sta (ptr1),y
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

; field width in a
; value width in x

; Pointer to string heap in A/X
; Field width in Y
.proc writeString
    sta ptr1
    stx ptr1 + 1
    cpy #0
    beq SK
    tya
    pha
    ldy #0
    lda (ptr1),y
    tax
    pla
    jsr leftpad
SK: ldy #0
    lda (ptr1),y
    tax
    beq DN
    ldy #0
    lda (ptr1),y
    iny
LP: lda (ptr1),y
    jsr CHROUT
    iny
    dex
    bne LP
DN: rts
.endproc

; This routine concatenates strings, char arrays, and characters
; into strings. The values can be any combination of:
;   a) A string variable
;   b) A string literal
;   c) A string object
;   d) An array of chars
;   e) A character
; A new string is allocated and returned in A/X.
;   ptr1 - pointer to string variable's position on stack
;   srcPtr - pointer to source
;   ptr4 - pointer to destination
; Inputs:
;   Pushed onto runtime stack in this order:
;       1) Data type of first string (pusha)
;       2) First string
;       3) Data type of second string
;   Second string in A/X

.proc concatString
    sta type1
    stx type2
    lda ptr1
    sta concat1
    lda ptr1 + 1
    sta concat1 + 1
    lda ptr2
    sta concat2
    lda ptr2 + 1
    sta concat2 + 1
    lda concat1
    ldx concat1 + 1
    ldy type1
    jsr getLength
    sta intOp1
    lda #0
    sta intOp1 + 1
    lda concat2
    ldx concat2 + 1
    ldy type2
    jsr getLength
    sta intOp2
    lda #0
    sta intOp2 + 1
    jsr addInt16
    lda intOp1 + 1
    beq :+
    lda #rteStringOverflow
    jsr runtimeError
:   lda intOp1
    clc
    adc #1
    ldx #0
    jsr heapAlloc
    sta strPtr
    sta ptr2
    stx strPtr + 1
    stx ptr2 + 1
    ldy #0
    lda intOp1
    sta (ptr2),y
    lda concat1
    sta ptr1
    lda concat1 + 1
    sta ptr1 + 1
    iny
    lda type1
    jsr concat
    lda concat2
    sta ptr1
    lda concat2 + 1
    sta ptr1 + 1
    lda type2
    jsr concat
    lda strPtr
    ldx strPtr + 1
    rts
.endproc

; Value in A/X, type in Y
.proc getLength
    cpy #TYPE_STRING_LITERAL
    beq SL
    cpy #TYPE_STRING_VAR
    beq SV
    cpy #TYPE_STRING_OBJ
    beq SV
    cpy #TYPE_ARRAY
    beq SA
    lda #1
    rts
SL: jmp strLiteralLength
SV: jmp strVarLength
SA: jmp arrayLength
.endproc

; String in A/X, returned in A.
.proc strVarLength
    sta ptr1
    stx ptr1 + 1
    ldy #0
    lda (ptr1),y
    rts
.endproc

.proc strLiteralLength
    sta ptr1
    stx ptr1 + 1
    ldy #0
:   lda (ptr1),y
    beq DN
    iny
    bne :-
DN: tya
    rts
.endproc

; Array in A/X, returned in A.
.proc arrayLength
    sta ptr1
    stx ptr1 + 1
    ldy #0
    lda (ptr1),y
    sta intOp2
    iny
    lda (ptr1),y
    sta intOp2 + 1
    iny
    lda (ptr1),y
    sta intOp1
    iny
    lda (ptr1),y
    sta intOp1 + 1
    jsr subInt16
    lda intOp1 + 1          ; Look at high byte of array length
    beq :+                  ; Branch if array <= 255
    lda #rteStringOverflow
    jsr runtimeError
:   inc intOp1              ; Length is actually upper - lower + 1
    lda intOp1
    rts
.endproc

; Type in A
; Y - offset in dest
; ptr1 - source
; ptr2 - dest
.proc concat
    cmp #TYPE_STRING_LITERAL
    beq SL
    cmp #TYPE_STRING_VAR
    beq SV
    cmp #TYPE_STRING_OBJ
    beq SV
    cmp #TYPE_ARRAY
    beq SA
    lda ptr1
    sta (ptr2),y
    iny
    rts
SL: jmp concatLiteral
SV: jmp concatStringVar
SA: jmp concatArray
.endproc

.proc concatLiteral
    sty tmp2
    lda #0
    sta tmp1
LP: ldy tmp1
    lda (ptr1),y
    beq DN
    ldy tmp2
    sta (ptr2),y
    inc tmp1
    inc tmp2
    bne LP
DN: ldy tmp2
    rts
.endproc

.proc concatStringVar
    sty tmp2
    lda #1
    sta tmp1
    ldy #0
    lda (ptr1),y
    tax
    beq DN
LP: ldy tmp1
    lda (ptr1),y
    ldy tmp2
    sta (ptr2),y
    inc tmp1
    inc tmp2
    dex
    bne LP
DN: ldy tmp2
    rts
.endproc

.proc concatArray
    sty tmp2
    lda #6
    sta tmp1
    lda ptr1
    ldx ptr1 + 1
    jsr arrayLength
    tax
LP: ldy tmp1
    lda (ptr1),y
    ldy tmp2
    sta (ptr2),y
    inc tmp1
    inc tmp2
    dex
    bne LP
    ldy tmp2
    rts
.endproc

; This routine reads a string of characters from the input
; and stores them in a string variable.  It skips spaces in
; the input until the first non-space.
;
; Inputs
;   A - nesting level of string variable
;   X - value offset on runtime stack
.proc readStringFromInput
    jsr calcStackOffset
    lda ptr1
    sta strPtr
    lda ptr1 + 1
    sta strPtr + 1
    jsr skipSpaces          ; Skip over spaces in the input buffer
    ; Calculate length of input
    lda inputBufUsed
    sec
    sbc inputPos
    ldx #0
    pha                     ; Save length of string buffer
    adc #1                  ; Add 1 for string length
    jsr heapAlloc
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

; This routine returns the string character at the given subscript.
;
; Pointer to string heap in A/X.
; String index on runtime stack.
;
; Character returned in A.  If index is 0, string length is returned.
.proc stringSubscript
    sta strPtr
    stx strPtr + 1
    jsr popax
    sta tmp1
    txa
    beq :+
    lda #rteValueOutOfRange
    jsr runtimeError
:   lda strPtr
    sta ptr1
    lda strPtr + 1
    sta ptr1 + 1
    ldy #0
    lda (ptr1),y
    cmp tmp1
    bcs :+
    lda #rteValueOutOfRange
    jsr runtimeError
:   ldy tmp1
    ldx #0
    lda (ptr1),y
    rts
.endproc
