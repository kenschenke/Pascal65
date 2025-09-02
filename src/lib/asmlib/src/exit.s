;
; exit.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Exit handler
;
; Copyright (c) 2024-2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "cbm_kernal.inc"
.include "zeropage.inc"

.export exit, _exit

exiting: .asciiz "exiting."

.proc _exit
    rts
.endproc

.proc exit
    lda #13
    jsr CHROUT
    lda #13
    jsr CHROUT
    ldx #0
:   lda exiting,x
    beq :+
    jsr CHROUT
    inx
    bne :-
    ; restore the stack pointer
:   ldx savedStackPtr
    txs
    ; call the exit handler
    jmp (exitHandler)
.endproc
