;
; rterror.s
; Ken Schenke (kenschenke@gmail.com)
;
; Runtime error handling
; 
; Copyright (c) 2024-2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;

.include "cbm_kernal.inc"
.include "zeropage.inc"

.export runtimeError

.import exit

.data

runtimeMsgs:
rteStackOverflowMsg: .asciiz "stack overflow"
rteValueOutOfRangeMsg: .asciiz "value out of range"
rteInvalidCaseValueMsg: .asciiz "invalid case value"
rteDivisionByZeroMsg: .asciiz "divide by zero"
rteInvalidFunctionArgumentMsg: .asciiz "invalid function argument"
rteInvalidUserInputMsg: .asciiz "invalid user input"
rteUnimplementedRuntimeFeatureMsg: .asciiz "unimplemented runtime feature"
rteOutOfMemoryMsg: .asciiz "out of memory"
rteStringOverflowMsg: .asciiz "string overflow"

.code

; Prints runtime error message to console and exits
; Runtime error code in A
.proc runtimeError
    sta tmp1            ; store the error number in tmp1
    ldx #0              ; use X as index for runtimeMsgs
    dec tmp1            ; decrement by 1 (runtimeMsgs is zero-based)
    ; If tmp1 is zero, print this error message
LL: lda tmp1            ; check if this is the message to print
    beq LP              ; it is - print it
    ; Look for the null terminator
LZ: lda runtimeMsgs,x   ; load the next character
    beq LN              ; branch if zero
    inx                 ; increment index
    bne LZ              ; go to the next character
LN: dec tmp1            ; decrement message number
    inx                 ; increment past the null terminator
    bne LL              ; branch if not the right message number yet
LP: lda runtimeMsgs,x   ; load the next character
    beq LD              ; if zero, branch because done
    jsr CHROUT          ; output the character
    inx                 ; increment the index
    bne LP              ; go to the next character
LD: jmp exit            ; exit back to BASIC
.endproc
