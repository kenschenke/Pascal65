;
; appendtopublicstring.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "runtime.inc"

.export appendToPublicString

.import publicString

.data

srcPtr: .word 0
appendPtr: .word 0
newStr: .word 0

.code

; String pointer in A/X
; tmp1 is used as index in source string
; tmp2 is current index in new string
; ptr2 is new string
.proc copyStr
    sta ptr1            ; Save string to append in ptr1
    stx ptr1 + 1
    lda #1              ; Start at first first character
    sta tmp1
    ldy #0              ; Load length of source string
    lda (ptr1),y
    beq DN              ; Branch if empty string
    tax                 ; Put string length in X
:   ldy tmp1            ; Load source index
    lda (ptr1),y        ; Load next char in source string
    ldy tmp2            ; Load destination index
    sta (ptr2),y        ; Store the next character
    inc tmp1            ; Increment source index
    inc tmp2            ; Increment dest index
    dex                 ; Decrement source character count
    bne :-              ; Branch if more chars left to copy
DN: rts
.endproc

.proc appendToPublicString
    lda #0              ; Load parameter (string pointer)
    jsr rtLibLoadParam
    sta appendPtr       ; Store the string pointer
    stx appendPtr + 1
    lda publicString    ; Load pointer to public string's value
    sta ptr2
    lda publicString + 1
    sta ptr2 + 1
    ldy #0
    lda (ptr2),y        ; Load the public string value
    sta srcPtr
    sta ptr1
    iny
    lda (ptr2),y
    sta srcPtr + 1      ; a pointer to the location on the runtime stack
    sta ptr1 + 1
    ldy #0              ; Look up the length of the source string
    lda (ptr1),y
    sta tmp1            ; Store the source string length in tmp1
    lda appendPtr
    sta ptr1
    lda appendPtr + 1
    sta ptr1 + 1        ; Look up the string length of the string to append
    lda (ptr1),y
    clc
    adc tmp1            ; Add it to the source string length
    pha                 ; Store the combined length
    adc #1              ; Add 1 to the combined length (for the string length byte)
    ldx #0
    jsr rtHeapAlloc     ; Allocate a buffer for the combined string
    sta newStr          ; Store the pointer to the new buffer
    sta ptr2            ; Put it in ptr2 as well (for copyStr)
    stx newStr + 1
    stx ptr2 + 1
    pla                 ; Pop the combined length back off the CPU stack
    ldy #0
    sta (ptr2),y        ; Store the combined length in the first spot of the new string
    iny
    sty tmp2            ; Store the current index for the combined string
    lda srcPtr
    ldx srcPtr + 1
    jsr copyStr         ; Copy the original source string into the new buffer
    lda appendPtr
    ldx appendPtr + 1
    jsr copyStr         ; Copy the appending string into the new buffer
    lda srcPtr
    ldx srcPtr + 1
    jsr rtHeapFree      ; Free the original source string
    lda publicString    ; Load the pointer to the public string value
    sta ptr1
    lda publicString + 1
    sta ptr1 + 1
    ldy #0
    lda newStr          ; Store the new string in the public string
    sta (ptr1),y
    lda newStr + 1
    iny
    sta (ptr1),y
    rts
.endproc
