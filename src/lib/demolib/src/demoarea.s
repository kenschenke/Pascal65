;
; demoarea.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "runtime.inc"
.include "types.inc"

.export demoArea

; Calculate the area by multiplying the first param x second param
.proc demoArea
    lda #0                  ; Look up the first parameter
    jsr rtLibLoadParam
    jsr rtPushEax           ; Push it to the runtime stack
    lda #1                  ; Look up the second parameter
    jsr rtLibLoadParam
    jsr rtPushEax           ; Push it to the runtime stack
    lda #TYPE_INTEGER       ; Both operands and result are integers
    tax
    tay
    jsr rtMultiply          ; Multiply the operands
    jsr rtPopEax            ; Pop the result off the runtime stack
    jmp rtLibReturnValue    ; Return it to the caller
.endproc
