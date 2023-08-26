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

runtimeMsgs:
    .byte <rteStackOverflowMsg,               >rteStackOverflowMsg
    .byte <rteValueOutOfRangeMsg,             >rteValueOutOfRangeMsg
    .byte <rteInvalidCaseValueMsg,            >rteInvalidCaseValueMsg
    .byte <rteDivisionByZeroMsg,              >rteDivisionByZeroMsg
    .byte <rteInvalidFunctionArgumentMsg,     >rteInvalidFunctionArgumentMsg
    .byte <rteInvalidUserInputMsg,            >rteInvalidUserInputMsg
    .byte <rteUnimplementedRuntimeFeatureMsg, >rteUnimplementedRuntimeFeatureMsg
    .byte <rteOutOfMemoryMsg,                 >rteOutOfMemoryMsg

.code

; Initialize the runtime error message table
.proc runtimeErrorInit
    rts
.endproc

; Prints runtime error message to console and exits
; Runtime error code in A
.proc runtimeError
    sta tmp1            ; store the error number in tmp1
    dec tmp1            ; decrement by 1 (runtimeMsgs is zero-based)
    asl tmp1            ; multiply by 2
    ldy tmp1            ; put the error number index in Y
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
