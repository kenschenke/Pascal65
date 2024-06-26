;
; exit.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Runtime error exit handler
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "cbm_kernal.inc"
.include "runtime.inc"

.import _printlnz
.export exit

.ifndef RUNTIME
.import _exit
.endif

.data

exiting: .asciiz "exiting."

.code

.proc exit
    lda #13
    jsr CHROUT
    lda #13
    jsr CHROUT
    lda #<exiting
    ldx #>exiting
    jsr _printlnz
.ifdef RUNTIME
    ; restore the stack pointer
    ldx savedStackPtr
    txs
    ; call the exit handler
    jmp (exitHandler)
.else
    lda #5
    ldx #0
    jmp _exit
.endif
.endproc
