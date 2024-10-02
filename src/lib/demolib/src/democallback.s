;
; democallback.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "runtime.inc"

.export registerCallbackProc, testCallbackProc
.export registerCallbackFunc, testCallbackFunc

.data

callbackProc: .dword 0
callbackFunc: .dword 0

.code

.proc registerCallbackProc
    ; Retrieve the routine pointer
    lda #0
    jsr rtLibLoadParam

    ; Store the routine pointer in callbackProc
    sta callbackProc
    stx callbackProc+1
    lda sreg
    sta callbackProc+2
    lda sreg+1
    sta callbackProc+3
    rts
.endproc

; Helper routine that pushes the routine pointer onto the stack
.proc pushCallbackProcAddr
    lda callbackProc+2
    sta sreg
    lda callbackProc+3
    sta sreg+1
    ldx callbackProc+1
    lda callbackProc
    jmp rtPushEax
.endproc

; Helper routine that pushes the routine pointer onto the stack
.proc pushCallbackFuncAddr
    lda callbackFunc+2
    sta sreg
    lda callbackFunc+3
    sta sreg+1
    ldx callbackFunc+1
    lda callbackFunc
    jmp rtPushEax
.endproc

.proc testCallbackProc
    ; Create the stack frame header
    jsr pushCallbackProcAddr
    jsr rtLibStackHeader

    ; Get the first parameter and pass it to the callback
    lda #0
    jsr rtLibLoadParam
    jsr rtPushEax

    ; Call the callback procedure
    jsr pushCallbackProcAddr
    jsr rtLibCallRoutine
    rts
.endproc

.proc registerCallbackFunc
    ; Get the routine pointer
    lda #0
    jsr rtLibLoadParam

    ; Store it in callbackFunc
    sta callbackFunc
    stx callbackFunc+1
    lda sreg
    sta callbackFunc+2
    lda sreg+1
    sta callbackFunc+3
    rts
.endproc

.proc testCallbackFunc
    ; Create the stack frame header
    jsr pushCallbackFuncAddr
    jsr rtLibStackHeader

    ; Call the Pascal Function
    jsr pushCallbackFuncAddr
    jsr rtLibCallRoutine

    ; Get the Function's return value
    jsr rtPopEax
    ; and return it to the caller
    jmp rtLibReturnValue
.endproc
