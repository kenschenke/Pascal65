.include "cbm_kernal.inc"
.include "runtime.inc"

.export exit

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
    ; call the exit handler
    jmp (exitHandler)
.endproc
