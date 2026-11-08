;
; rterror.s
; Ken Schenke (kenschenke@gmail.com)
;
; Runtime error handling
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;

.include "cbm_kernal.inc"
.include "runtime.inc"
.include "error.inc"

.export runtimeError, runtimeErrorInit
.export noDynArrays, noFiles, noTrig

.import exit

.data

; One message for each rte* code in error.inc, in order. runtimeError
; indexes them with an 8-bit register, so they must fit in 256 bytes.
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
rteInvalidFileHandleMsg: .asciiz "invalid file handle"
rteFileOpenFailedMsg: .asciiz "file open failed"
rteFileIOFailedMsg: .asciiz "file i/o failed"
rtePackageNotLinkedMsg: .asciiz "runtime package not linked:"
runtimeMsgsEnd:
.assert runtimeMsgsEnd - runtimeMsgs <= 256, error, "runtime messages too long"

.code

; Initialize the runtime error message table
.proc runtimeErrorInit
    rts
.endproc

; Prints runtime error message to console and exits
; Runtime error code in A
.proc runtimeError
    jsr printRuntimeMsg
    jmp exit            ; exit back to BASIC
.endproc

; Prints the message for the runtime error code in A
.proc printRuntimeMsg
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
LD: rts
.endproc

; The core's jump table entries for a runtime package point at these stubs
; until codegen links the package and patches them (see rtpkg.inc). Each
; stub raises rtePackageNotLinked and prints the package number (RT_PKG_*
; in asm.inc).
;
; The stubs are 3 bytes apart: each skips the next one's LDA with a BIT
; absolute ($2c). The rtpkgnone compiler test relies on that layout.
noDynArrays:
    lda #1              ; RT_PKG_DYNARRAYS
    .byte $2c
noFiles:
    lda #2              ; RT_PKG_FILES
    .byte $2c
noTrig:
    lda #3              ; RT_PKG_TRIG
    pha
    lda #rtePackageNotLinked
    jsr printRuntimeMsg
    lda #' '
    jsr CHROUT
    pla
    ora #'0'
    jsr CHROUT
    jmp exit
