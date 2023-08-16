; Handle runtime error

.include "cbm_kernal.inc"

.import exit

.ifdef RUNTIME
.include "runtime.inc"
.import printz
.else
.import _printz
.importzp ptr1, tmp1
.endif

.export runtimeError, runtimeErrorInit

.data

rteStackOverflowMsg: .asciiz "stack overflow"
rteValueOutOfRangeMsg: .asciiz "value out of range"
rteInvalidCaseValueMsg: .asciiz "invalid case value"
rteDivisionByZeroMsg: .asciiz "divide by zero"
rteInvalidFunctionArgumentMsg: .asciiz "invalid function argument"
rteInvalidUserInputMsg: .asciiz "invalid user input"
rteUnimplementedRuntimeFeatureMsg: .asciiz "unimplemented runtime feature"
rteOutOfMemoryMsg: .asciiz "out of memory"

.bss

runtimeMsgs: .res 16

.code

; Initialize the runtime error message table
.proc runtimeErrorInit
    ldy #0
    lda #<runtimeMsgs
    sta ptr1
    lda #>runtimeMsgs
    sta ptr1 + 1

    lda #<rteStackOverflowMsg
    sta (ptr1),y
    iny
    lda #>rteStackOverflowMsg
    sta (ptr1),y
    iny

    lda #<rteValueOutOfRangeMsg
    sta (ptr1),y
    iny
    lda #>rteValueOutOfRangeMsg
    sta (ptr1),y
    iny

    lda #<rteInvalidCaseValueMsg
    sta (ptr1),y
    iny
    lda #>rteInvalidCaseValueMsg
    sta (ptr1),y
    iny

    lda #<rteDivisionByZeroMsg
    sta (ptr1),y
    iny
    lda #>rteDivisionByZeroMsg
    sta (ptr1),y
    iny

    lda #<rteInvalidFunctionArgumentMsg
    sta (ptr1),y
    iny
    lda #>rteInvalidFunctionArgumentMsg
    sta (ptr1),y
    iny

    lda #<rteInvalidUserInputMsg
    sta (ptr1),y
    iny
    lda #>rteInvalidUserInputMsg
    sta (ptr1),y
    iny

    lda #<rteUnimplementedRuntimeFeatureMsg
    sta (ptr1),y
    iny
    lda #>rteUnimplementedRuntimeFeatureMsg
    sta (ptr1),y
    iny

    lda #<rteOutOfMemoryMsg
    sta (ptr1),y
    iny
    lda #>rteOutOfMemoryMsg
    sta (ptr1),y
    
    rts
.endproc

; Prints runtime error message to console and exits
; Runtime error code in A
.proc runtimeError
    sta tmp1
    dec tmp1
    asl tmp1
    ldy tmp1
    lda #<runtimeMsgs
    sta ptr1
    lda #>runtimeMsgs
    sta ptr1 + 1
    iny
    lda (ptr1),y
    tax
    dey
    lda (ptr1),y
.ifdef RUNTIME
    jsr printz
.else
    jsr _printz
.endif
    jmp exit
.endproc
