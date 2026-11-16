;
; exit.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Exit handler
;
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "cbm_kernal.inc"
.include "runtime.inc"

.export exit

.import irqCleanup

exiting: .asciiz "exiting."

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
    ; Put the KERNAL's IRQ handler back. The program's cleanup skips the
    ; libraries', which do it.
    jsr irqCleanup
    ; call the exit handler
    jmp (exitHandler)
.endproc
