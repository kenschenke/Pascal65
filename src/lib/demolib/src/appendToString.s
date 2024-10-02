;
; appendtostring.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "runtime.inc"

.export appendToString

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

.proc appendToString
    lda #1              ; Load second parameter (string pointer)
    jsr rtLibLoadParam
    sta appendPtr       ; Store the string pointer
    stx appendPtr + 1
    lda #0              ; Load first parameter
    jsr rtLibLoadParam
    sta ptr2            ; 2nd param is by reference so it's
    stx ptr2 + 1        ; a pointer to the location on the runtime stack
    ldy #0
    lda (ptr2),y        ; de-reference the pointer to get access to
    sta srcPtr          ; the underlying string pointer
    sta ptr1            ; store the source string pointer in ptr1 as well
    iny
    lda (ptr2),y
    sta srcPtr + 1
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
    lda newStr
    ldx newStr + 1
    ldy #0
    ; Store the new string buffer back into the first parameter
    jmp rtLibStoreVarParam
.endproc
